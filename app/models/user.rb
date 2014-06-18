class User < ActiveRecord::Base

  attr_accessor :use_google_oauth_registration

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :use_google_oauth_registration

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  has_many :credentials, :dependent => :destroy

  devise :database_authenticatable, :registerable, :rememberable, :trackable, :confirmable

  before_validation :_capture_employee_business
  before_validation :_defaults, :if => :new_record?

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id, :message => "is already taken" }

  validates :first_name, :last_name, :business, :presence => true, :if => Proc.new { |u| !(u.new_record? && u.use_google_oauth_registration) }
  validate :_employee_or_client

  #
  # CHECK THIS OUT; ISNT WORKING RIGHT.
  #
  # validates :employee_id, :uniqueness => { :message => "is already associated with another user" }

  before_save :_handle_new_business_owner

  after_initialize :_default_creation_type

  scope :google_oauth2, lambda { |email| joins(:credentials).includes(:credentials).where('credentials.provider = ? and credentials.email = ?', :google_oauth2, email) }
  scope :cb, lambda { where('users.business_id = ?', Business.current.try(:id)) }

  def self.find_for_google_oauth2(auth, current_user)
    # user exists
    user = cb.google_oauth2(auth[:info][:email]).first
    return user if user

    # does not exist. require open invite.
    invitation = Invitation.cb.open.find_by_email auth[:info][:email]
    if invitation
      # invited user
      user = if current_user.nil?
               user = User.new_from_auth(auth[:info])
             else
               # apparently, we're taking ownership of a new credential....?
               current_user
             end
      user.credentials.push(Credential.new_from_google_oauth2(auth, user))
      return nil if !invitation.accept_user!(user) # credential likely is already in use for this business
    elsif current_user.nil?
      invitation = Invitation.handled.open.find_by_email auth[:info][:email]
      if invitation
        user = User.new_from_auth(auth[:info])
        user.credentials.push(Credential.new_from_google_oauth2(auth, user))
        return nil if !invitation.accept_user!(user)
      end
    elsif current_user
      # this is pretty much a weird login....current_user is trying to relogin with no
      # invitation or new business. why? log him out.
      return nil 
    else
      return nil
    end

    user
  end

  def self.new_from_auth(info)
    user = new
    user.email = info[:email]
    user.first_name = info[:first_name]
    user.last_name = info[:last_name]
    user.confirmed_at = Time.now  # google users are auto-confirmed
    user
  end

  def become_owner_of_new_business(handle)
    @business = Business.new
    @business.handle = handle if handle # this will trigger validations properly...
    @employee = Employee.new
    @employee.business = @business        
    self.employee = @employee
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

  def use_google_oauth_registration=(value)
    @use_google_oauth_registration = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end

  def _defaults
    self.business = Business.current if business.nil?
    self.timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end

  def _employee_or_client
    errors.add(:base, 'must be associated with employee or client of this business') if (self.employee.nil? && self.client.nil?)
  end

  def _capture_employee_business
    if employee && employee.new_record? && employee.business && employee.business.new_record?
      self.business = employee.business    
    end
  end

  def _handle_new_business_owner
    if employee && employee.new_record? && employee.business && employee.business.new_record?
      employee.email = email
      employee.role = Employee::Roles::OWNER
      if !employee.business.save || !employee.save
        employee.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.employee')}: #{m}") }
        employee.business.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.business')}: #{m}") }
        errors.add(:base, I18n.t('users.new_business_failed'))
      end
    end
  end

  def _default_creation_type
    self.use_google_oauth_registration = true if new_record? && self.use_google_oauth_registration.nil?
  end

  
end

