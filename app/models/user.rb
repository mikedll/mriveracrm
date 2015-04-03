class User < ActiveRecord::Base

  include ActionView::Helpers::TranslationHelper

  attr_accessor :use_google_oauth_registration, :conflicting_invitation, :tos_agreement

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :use_google_oauth_registration, :tos_agreement

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  has_many :credentials, :dependent => :destroy

  devise :database_authenticatable, :registerable, :rememberable, :trackable, :confirmable

  after_initialize :_default_creation_type

  before_validation { @virtual_path = 'user' }
  before_validation :_capture_business
  before_validation :_defaults, :if => :new_record?

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id, :message => "is already taken" }
  validates :first_name, :last_name, :business, :presence => true, :if => Proc.new { |u| !(u.new_oauthed_user?) }
  validates :password, :length => { :minimum => 8 }, :if => lambda { |u| !u.new_oauthed_user? && u.credentials.empty?  }
  validates_confirmation_of :password, :if => lambda { |u| u.credentials.empty? }
  validate :_employee_or_client
  validate :_agrees_to_tos, :if => :new_record?

  #
  # CHECK THIS OUT; ISNT WORKING RIGHT.
  #
  # validates :employee_id, :uniqueness => { :message => "is already associated with another user" }

  before_save :_create_new_business_if_necessary

  after_save :_notify_subscription, :if => lambda { |r|
    r.employee && r.employee.owner? &&

    # confirmed with non-oauth login
    ((!r.new_record? && r.confirmed_at_changed? && !confirmed_at.nil?) ||

      # immediately confirmed with new business via oauth
      (r.new_record? && r.business_id_changed?))
  }

  scope :google_oauth2, lambda { |email| joins(:credentials).includes(:credentials).where('credentials.provider = ? and credentials.email = ?', :google_oauth2, email) }
  scope :cb, lambda { where('users.business_id = ?', Business.current.try(:id)) }

  def self.find_for_google_oauth2(auth, current_user)
    # user exists
    user = cb.google_oauth2(auth[:info][:email]).first
    return user if user

    # does not exist. require open invite.
    invitation = Invitation.cb.open.find_by_email auth[:info][:email].downcase
    if invitation
      # invited user
      user = if current_user.nil?
               user = User.new_from_auth(auth[:info])
             else
               # apparently, we're taking ownership of a new credential....?
               current_user
             end
      user.credentials.push(Credential.new_from_google_oauth2(auth, user))
      return user if !invitation.accept_user!(user) # credential likely is already in use for this business
    elsif current_user.nil? && cb.first.nil?
      invitation = Invitation.handled.open.find_by_email auth[:info][:email].downcase
      if invitation
        user = User.new_from_auth(auth[:info])
        user.credentials.push(Credential.new_from_google_oauth2(auth, user))
        return nil if !invitation.accept_user!(user)
      else
        u = User.new
        u.errors.add(:base, I18n.t('user.errors.no_invitation', :email => auth[:info][:email]))
        return u
      end
    elsif current_user
      # this is pretty much a weird login....current_user is trying to relogin with no
      # invitation or new business. why? log him out.
      return nil
    else
      u = User.new
      u.errors.add(:base, I18n.t('user.errors.no_invitation', :email => auth[:info][:email]))
      return u
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
    business = Business.new
    business.handle = handle if handle # this will trigger validations properly...
    employee = Employee.new
    employee.business = business
    employee.email = email
    employee.role = Employee::Roles::OWNER # if you create a business, you're the owner.
    self.employee = employee
    self.business = business
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

  def tos_agreement=(value)
    @tos_agreement = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
  end

  def new_oauthed_user?
    new_record? && use_google_oauth_registration
  end


  def _defaults
    self.business = Business.current if business.nil?
    self.timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end

  def _employee_or_client
    errors.add(:base, 'must be associated with employee or client of this business') if (self.employee.nil? && self.client.nil?)
  end

  def _capture_business
    if business.nil? && employee && employee.new_record? && employee.business && employee.business.new_record?
      self.business = employee.business
    end
  end

  def _create_new_business_if_necessary

    # note: some of the following checks on changed or new_record
    # shouldn't be necessary due to how active-record automatically
    # saves associations on a given record R before saving R itself.

    if employee && employee.business && (employee.business.new_record? || employee.business.changed?) && (!employee.business.errors.empty? || !employee.business.save)
      errors.add(:base, I18n.t('users.new_business_failed'))
      employee.business.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.business')}: #{m}") }
      return false
    end

    if employee && (employee.new_record? || employee.changed?) && (!employee.errors.empty? && !employee.save)
      employee.errors.full_messages.each { |m| errors.add(:base, "#{I18n.t('activemodel.models.employee')}: #{m}") }
      errors.add(:base, I18n.t('users.new_business_employee_failed'))
      return false
    end
  end

  def _default_creation_type
    self.use_google_oauth_registration = true if new_record? && self.use_google_oauth_registration.nil?
  end

  protected

  def _agrees_to_tos
    errors.add(:base, I18n.t('user.errors.tos_agreement_required')) if !tos_agreement
  end

  def _notify_subscription
    employee.business.usage_subscription.reload # trial is inserted into the db on post-create hook.
    employee.business.usage_subscription.notify_signup!
  end

end

