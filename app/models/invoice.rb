class Invoice < ActiveRecord::Base
  belongs_to :business
  belongs_to :client

  has_many :transactions

  state_machine :status, :initial => :open do

    event :mark_pending do
      transition [:open] => [:pending]
    end

    event :fail_payment do
      transition [:open, :pending, :failed_payment] => [:failed_payment]
    end

    event :mark_paid do
      transition [:open, :pending, :failed_payment] => [:paid]
    end

    event :close do
      transition [:open, :pending, :failed_payment] => [:closed]
    end

    state :open, :pending, :failed_payment, :closed do
      def can_pay?
        true
      end
    end

    state :paid do
      def can_pay?
        false
      end
    end

  end

  attr_accessible :description, :total, :date, :title

  validates :client, :date, :total, :presence => true
  validates :description, :length => { :minimum => 3 }

  before_validation :_defaults

  def charge!
    self.client.payment_gateway_profile.pay!(self)
  end

  def public
    {
      :title => title,
      :description => description,
      :total => total,
      :can_pay => can_pay?,
      :date => date,
      :status => status
    }    
  end


  private

  def _defaults
    if new_record?
      self.description = "..." if description.nil?
      self.total = 0.0 if total.nil?
      self.date = Time.now if date.nil?
      self.title = "New invoice" if title.nil?
    end
  end

end
