class Client < ActiveRecord::Base

  belongs_to :business
  has_many :users
  has_many :invitations
  has_many :invoices
  has_one :payment_gateway_profile


  attr_accessible :first_name, :last_name, :email

  validates :business_id, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

  validate :_static_business

  after_create :_require_payment_gateway_profile

  scope :cb, lambda { where('clients.business_id = ?', Business.current.try(:id)) }

  def _static_business
    if persisted? && business_id_changed?
      errors.add(:base, "cannot change business of client")
    end
  end

  def display_name
    "#{first_name} #{last_name}"    
  end

  def _require_payment_gateway_profile
    if payment_gateway_profile.nil?
      self.payment_gateway_profile = AuthorizeNetPaymentGatewayProfile.new
      self.payment_gateway_profile.save!
    end
  end

  def destroy
    raise "Clients cannot be destroyed."
  end


end
