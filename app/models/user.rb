class User < ActiveRecord::Base

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :use_google_oauth_registration

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  has_many :credentials, :dependent => :destroy

  devise :database_authenticatable, :registerable, :rememberable, :trackable, :confirmable

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id, :message => "is already taken" }

  #
  # CHECK THIS OUT; ISNT WORKING RIGHT.
  #
  # validates :employee_id, :uniqueness => { :message => "is already associated with another user" }

  before_validation :_handle_new_business_owner
  before_validation :_defaults, :if => :new_record?

  after_initialize :_default_creation_type

  validates :first_name, :last_name, :business, :presence => true
  validate :_employee_or_client

  scope :google_oauth2, lambda { |email| joins(:credentials).includes(:credentials).where('credentials.provider = ? and credentials.email = ?', :google_oauth2, email) }
  scope :cb, lambda { where('users.business_id = ?', Business.current.try(:id)) }

  attr_accessor :use_google_oauth_registration

  def self.find_for_google_oauth2(auth, current_user)
    # user exists
    user = cb.google_oauth2(auth[:info][:email]).first
    return user if user

    # does not exist. require open invite.
    invitation = Invitation.cb.open.find_by_email auth[:info][:email]
    return nil if invitation.nil?

    user = if current_user.nil?
             user = User.new
             user.email = auth[:info][:email]
             user.first_name = auth[:info][:first_name]
             user.last_name = auth[:info][:last_name]    
             user.confirmed_at = Time.now  # google users are auto-confirmed
             user
           else
             current_user
           end
    user.credentials.push(Credential.new_from_google_oauth2(auth, user))

    return nil if !invitation.accept_user!(user) # credential likely is already in use for this business

    user
  end

  def cb?
    business_id == Business.current.id
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def login_name
    "#{first_name} #{last_name} (#{self.email})"
  end

  def _defaults
    self.business = Business.current if business.nil?
    self.timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end

  def _employee_or_client
    errors.add(:base, 'must be associated with employee or client of this business') if (self.employee.nil? && self.client.nil?)
  end

  def _handle_new_business_owner
    if employee && employee.new_record? && employee.business && employee.business.new_record?
      employee.email = email
      employee.role = Employee::Roles::OWNER
      if !employee.business.save || !employee.save
        employee.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.employee')}: #{m}") }
        employee.business.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.business')}: #{m}") }
        errors.add(:base, I18n.t('users.new_business_failed'))
      else
        self.business = employee.business
      end
    end
  end

  def _default_creation_type
    self.use_google_oauth_registration = true if new_record?
  end

  
end

