class Client < ActiveRecord::Base

  belongs_to :business
  has_many :users
  has_many :invitations
  has_many :notes, :dependent => :destroy
  has_many :invoices
  has_one :payment_gateway_profile, as: :payment_gateway_profilable


  attr_accessible :company, :first_name, :last_name, :email, :website_url, :skype_id, :last_contact_at, :next_contact_at, :phone, :phone_2, :address_line_1, :address_line_2, :city, :state, :zip, :archived, :updated_at

  validates :business_id, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }, :if => Proc.new { |c| !c.email.blank? }
  validates :zip, :format => { :with => Regexes::ZIP }, :if => Proc.new { |c| !c.zip.blank? }

  validate :_static_business

  before_validation :_strip_fields

  after_create :require_payment_gateway_profile

  INACTIVE_THRESHOLD = 30.days
  RECENT_TRANSACTION_THRESHOLD = INACTIVE_THRESHOLD
  scope :with_transactions, lambda { includes(:invoices => :transactions) }
  scope :cb, lambda { where('clients.business_id = ?', Business.current.try(:id)) }
  scope :unarchived, where('archived = ?', false)
  scope :archived, where('archived = ?', true)
  scope :recently_modified, where('updated_at > ?', Time.now - 1.week)
  scope :with_users, lambda { includes(:users) }
  scope :without_active_users, lambda {
    with_users.where('NOT EXISTS(SELECT id FROM users WHERE users.client_id = clients.id AND users.last_sign_in_at > ?)', Time.now - INACTIVE_THRESHOLD)
  }
  scope :with_active_card_info, lambda { joins(:payment_gateway_profile).where("payment_gateway_profiles.card_last_4 <> ''") }
  scope :without_recent_transaction, lambda {
    where('NOT EXISTS(
SELECT id
FROM invoices as invoices
WHERE invoices.client_id = clients.id
LEFT INNER JOIN transactions ON transactions.invoice_id = invoices.id
WHERE
    transactions.status = "successful"
AND transactions.updated_at > ?
)', Time.now - RECENT_TRANSACTION_THRESHOLD)
  }
  scope :without_recent_payment_info_write, lambda { joins(:payment_gateway_profile).where('payment_gateway_profiles.last_written is null or payment_gateway_profiles.last_written < ?', Time.now - INACTIVE_THRESHOLD) }
  scope :with_dormant_payment_info, lambda { without_recent_payment_info_write.without_recent_transaction }

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

  def handle_inactive_payment_info!
    payment_gateway_profile.erase_sensitive_information! if payment_gateway_profile
  end

  def handle_inactive!
    handle_inactive_payment_info!
    users.each { |u| u.destroy }
  end

  def addressee
    first_name.blank? ? company : first_name
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

  def payment_gateway_profilable_remote_app_key
    business.stripe_secret_key
  end

  def payment_gateway_profilable_subscribable?
    false
  end

  def payment_gateway_profilable_desc_attrs
    { :description => payment_profile_description, :email => email}
  end

  def payment_profile_profilable_card_args
    {
      :first_name => first_name,
      :last_name => last_name,
    }
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
