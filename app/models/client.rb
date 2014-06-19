class Client < ActiveRecord::Base

  belongs_to :business
  has_many :notes
  has_many :users
  has_many :invitations
  has_many :invoices
  has_one :payment_gateway_profile


  attr_accessible :company, :first_name, :last_name, :email, :website_url, :skype_id, :last_contact_at, :next_contact_at, :phone, :phone2, :address_line_1, :address_line_2, :city, :state, :zip, :archived, :updated_at

  validates :business_id, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }, :if => Proc.new { |c| !c.email.blank? }
  validates :zip, :format => { :with => Regexes::ZIP }, :if => Proc.new { |c| !c.zip.blank? }

  validate :_static_business

  before_validation :_strip_fields

  after_create :require_payment_gateway_profile

  scope :cb, lambda { where('clients.business_id = ?', Business.current.try(:id)) }
  scope :unarchived, where('archived = ?', false)
  scope :archived, where('archived = ?', true)
  scope :recently_modified, where('updated_at > ?', Time.now - 1.week)

  def archive!
    if archived?
      self.errors.add(:base, "Client is already archived") 
      return false
    end
      
    self.update_attributes(:archived => true)
  end

  def unarchive!
    if !archived?
      self.errors.add(:base, "Client is not archived") 
      return false
    end

    self.update_attributes(:archived => false)
  end

  def _static_business
    if persisted? && business_id_changed?
      errors.add(:base, "cannot change business of client")
    end
  end

  def invite
    invitation = self.invitations.build
    invitation.email = email
    invitation.business = business
    invitation.save!
    invitation
  end


  def display_name
    "#{first_name} #{last_name}"
  end

  def require_payment_gateway_profile
    if payment_gateway_profile.nil? && !business.stripe_secret_key.blank?
      self.payment_gateway_profile = StripePaymentGatewayProfile.new
      self.payment_gateway_profile.save!
    end
  end

  def payment_profile_description
    if !company.blank?
      company
    elsif !display_name.blank?
      display_name
    else
      id
    end
  end

  def _strip_fields
    self.zip.strip!
    self.address_line_1.strip!
    self.address_line_2.strip!
    self.phone.strip!
    self.phone_2.strip!
    self.state.strip!
    self.city.strip!
    self.website_url.strip!
  end

end
