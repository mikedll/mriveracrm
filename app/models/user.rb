class User < ActiveRecord::Base

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  has_many :credentials, :dependent => :destroy

  devise :omniauthable

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id, :message => "is already taken" }

  #
  # CHECK THIS OUT; ISNT WORKING RIGHT.
  #
  # validates :employee_id, :uniqueness => { :message => "is already associated with another user" }

  validates :first_name, :last_name, :business, :presence => true
  validate :_employee_or_client
  before_validation :_defaults, :if => :new_record?

  scope :google_oauth2, lambda { |email| joins(:credentials).includes(:credentials).where('credentials.provider = ? and credentials.email = ?', :google_oauth2, email) }
  scope :cb, lambda { where('users.business_id = ?', Business.current.try(:id)) }

  def self.find_for_google_oauth2(auth, current_user)

    # user exists
    user = cb.google_oauth2(auth[:info][:email]).first
    return user if user

    # does not exist. require open invite.
    invitation = Invitation.cb.open.find_by_email auth[:info][:email]
    return User.new if invitation.nil?

    credential = Credential.new(:provider => :google_oauth2,
                                :uid => auth[:uid], 
                                :email => auth[:info][:email],
                                :name =>  auth[:info][:name],
                                :oauth2_access_token => auth[:credentials][:token],
                                :oauth2_access_token_expires_at => Time.at(auth[:credentials][:expires_at]),
                                :oauth2_refresh_token => auth[:credentials][:refresh_token])

    if current_user
      credential.user = current_user
    else
      user = User.new
      user.email = credential.email
      user.first_name = auth[:info][:first_name]
      user.last_name = auth[:info][:last_name]
      credential.user = user
    end

    return User.new  if invitation.accept_user!(credential.user) # credential likely is already in use for this business
    credential.user
  end

  def cb?
    business_id == Business.current.id
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def _defaults
    self.business = Business.current
    self.timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end

  def _employee_or_client
    errors.add(:base, 'must be associated with employee or client of this business') if (self.employee.nil? && self.client.nil?)
  end

  
end

