class Invoice < ActiveRecord::Base
  belongs_to :client

  has_many :transactions
  has_many :outside_transactions
  has_many :stripe_transactions

  include PersistentRequestable
  include ActionView::Helpers::TranslationHelper
  include ActionView::Helpers::NumberHelper

  PDF_GENERATION = 'PDFGeneration'

  mount_uploader :pdf_file, PdfUploader

  #
  # Open
  # Pending
  # { Failed Payment,    Cancelled }
  # { Paid, Closed }
  state_machine :status, :initial => :open do

    event :cancel do
      transition [:pending] => [:cancelled]
    end

    event :mark_pending do
      transition [:open] => [:pending]
    end

    event :fail_payment do
      transition [:pending, :failed_payment] => [:failed_payment]
    end

    event :mark_paid do
      transition [:pending, :failed_payment] => [:paid]
    end

    event :close do
      transition [:pending, :failed_payment] => [:closed]
    end

    # Delete, edit.
    state :open do
      def can_delete?
        true
      end

      def can_edit?
        true
      end
    end

    state all - [:open] do
      def can_delete?
        false
      end

      def can_edit?
        false
      end
    end

    # Pay
    state :pending, :failed_payment do
      def can_pay?
        true
      end
    end

    state all - [:pending, :failed_payment] do
      def can_pay?
        false
      end
    end

    # Cancel
    state :pending do
      def can_cancel?
        true
      end
    end

    state all - [:pending] do
      def can_cancel?
        false
      end
    end

  end

  attr_accessible :description, :total, :date, :title

  before_validation { @virtual_path = 'invoice' }
  before_validation :_defaults_and_formatting
  before_validation :_verify_can_edit?

  validates :client, :date, :total, :presence => true
  validates :description, :length => { :minimum => 3 }
  validate :_can_mark_paid

  after_save :_enqueue_pdf_generation

  before_destroy :_verify_destroyable

  scope :viewable_to_client, lambda {
    where('invoices.status in (?)', [:pending, :failed_payment, :paid, :closed])
  }

  default_scope { order('created_at asc') }

  class Worker < WorkerBase
  end

  def pretty_date
    I18n.l(date, :format => :dateonly)
  end

  def pretty_total
    number_to_currency(total)
  end

  def charge!
    if !can_pay?
      errors.add(:base, t('.cannot_pay'))
      return false
    end

    if self.client.payment_gateway_profile.nil?
      errors.add(:base, I18n.t('payment_gateway_profile.not_ready_for_payments'))
      return false
    end

    self.client.payment_gateway_profile.pay_invoice!(self).tap do |result|
      errors.add(:base, self.client.payment_gateway_profile.last_error) if !result
    end
  end

  def public
    {
      :id => id,
      :title => title,
      :description => description,
      :total => total,
      :can_pay => can_pay?,
      :can_edit => can_edit?,
      :date => date,
      :status => status
    }
  end

  def regenerate_pdf
    _capture_as_pdf
  end

  private

  def _defaults_and_formatting
    if new_record?
      self.description = "..." if description.nil?
      self.total = 0.0 if total.nil?
      self.date = Time.now if date.nil?
      self.title = "New invoice" if title.nil?
    end

    self.status = status.to_s if status.instance_of?(Symbol)
  end

  def _verify_can_edit?
    internal_attributes = ["status", "pdf_file", "pdf_file_unique_id", "pdf_file_original_filename"]
    errors.add(:base, t('.uneditable')) if !new_record? && (changed.reject { |attr| internal_attributes.include?(attr) }.count > 0) && !can_edit?
  end

  def _verify_destroyable
    if !can_delete?
      errors.add(:base, I18n.t('invoice.cannot_delete'))
      return false
    end
  end

  def _can_mark_paid
    if status_changed? && status == 'paid' && self.transactions.successful.empty?
      self.errors.add(:transactions, 'must include at least one successful transaction')
    end
  end

  def _capture_as_pdf
    if can_edit?
      errors.add(:pdf_file, I18n.t('invoice.cannot_generate_pdf'))
      return false
    end

    return false if !start_persistent_request(PDF_GENERATION)

    Worker.obj_enqueue(self, :capture_as_pdf_background)
    true
  end

  def capture_as_pdf_background
    pdf_root = Rails.root.join("tmp/pdfs")
    html_filename = pdf_root.join("invoice#{self.id}.html")
    pdf_filename = "#{File.dirname(html_filename)}/#{File.basename(html_filename, ".*")}.pdf"

    invoice = self
    File.open(html_filename, "w") do |f|
      f.write ERB.new(File.read(Rails.root.join('app/views/invoices/invoice_pdf.html.erb'))).result(binding)
    end

    Dir.chdir(pdf_root) do
      cmd = "xhtml2pdf #{html_filename}"
      result = %x[#{cmd}]
    end

    FileUtils.rm_rf(html_filename)
    self.pdf_file = File.new(pdf_filename, "r")
    save!
    FileUtils.rm_rf(pdf_filename)
    stop_persistent_request(PDF_GENERATION)
  end

  def _enqueue_pdf_generation
    _capture_as_pdf if !pdf_file? && !can_edit?
  end

end
