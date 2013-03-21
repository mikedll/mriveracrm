class User < ActiveRecord::Base

  has_many :credentials

  has_many :contact_relationships
  has_many :clients, :through => :contact_relationships

  has_many :employments
  has_many :business, :through => :employments

  devise :omniauthable

  validates :email, :format => { :with => Regexes::EMAIL }
  validates :first_name, :last_name, :presence => true

  before_validation :_default_timezone, :if => :new_record?

  scope :by_credential, lambda { |email| joins(:credentials).where('credentials.email = ?', email) }
  scope :by_employment, lambda { |b| joins(:employments => :businesses).where('businesses.id = ?', b.id) }
  scope :by_contact_relationship, lambda { |b| joins(:contact_relationships => :businesses).where('businesses.id = ?', b.id) }

  def self.find_for_google_oauth2(auth, current_user, current_business)

    # user exists
    user = by_employment(current_business).by_credential_email(auth[:info][:email]).first || by_contact_relationship(current_business).by_credential_email(auth[:info][:email]).first
    return user if user

    # does not exist. require open invite.
    invitation = Invitation.open.by_business(current_business).find_by_email auth[:info][:email]
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
      credential.save!
    else
      user = User.new
      user.email = credential.email
      user.first_name = auth[:info][:first_name]
      user.last_name = auth[:info][:last_name]
      user.save! # not sure if this is needed
      credential.user = user
      credential.save!
    end
    invitation.accept_user!(credential.user)
    credential.user
  end

  def display_name
    "#{first_name} #{last_name}"
  end

  def client
    clients.first
  end

  def business
    businesses.first
  end

  def _default_timezone
    timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end
  
end

