class Transaction < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :payment_gateway_profile


  include ActionView::Helpers::TranslationHelper


  validates :type, :presence => true

  before_validation { @virtual_path = 'transaction' }
  after_validation :add_transition_errors
  validate :_verify_payable_invoice
  validate :_verify_can_edit?
  before_destroy :_verify_destroyable
  before_create :_default_amount

  attr_accessible :amount, :status, :outside_id, :outside_vendor

  state_machine :status, :initial => :open do

    event :begin do
      transition [:open] => [:pending]
    end

    event :has_failed do
      transition [:pending] => [:failed]
    end

    event :succeed do
      transition [:pending] => [:successful]
    end

    state :open do
      def can_delete?; true; end
    end

    state all - [:open] do
      def can_delete?; false; end
    end
  end

  scope :successful, where(:status => :successful)

  def editable_type?
    (self.is_a?(OutsideTransaction))
  end


  def to_editor
    self.attributes.merge(:type => self.type, 
                          :succeedable => (open? && editable_type?),
                          :destroyable => (open? && editable_type?))
  end

  # need to do this better...currently have to call this from outside the class
  def add_transition_errors
    if !self.errors[:status].blank?
      self.errors.delete(:status)
      self.errors.add(:status, t('transaction.errors.status', :status => self.status))
    end
  end

  # not sure why this doesnt work with the states...
  def can_edit?
    self.status == "open"
  end

  protected

  def _verify_can_edit?
    errors.add(:base, t('.errors.uneditable')) if !new_record? && ((changed.reject { |attr| ["status", "vendor_id"].include?(attr) }.count > 0) && (!editable_type? || !can_edit?))
  end

  def _verify_destroyable
    if !self.is_a?(OutsideTransaction)
      errors.add(:base, I18n.t('.errors.cannot_destroy_this_type')) 
      return false
    end

    if !can_delete?
      errors.add(:base, I18n.t('.errors.cannot_destroy_in_state')) 
      return false
    end    

  end

  def _verify_payable_invoice
    self.errors.add(:invoice, I18n.t('invoice.cannot_pay')) if !self.invoice.can_pay?
  end


  def _default_amount
    self.amount = self.invoice.total if new_record? && self.amount == 0.0
  end

end

