class Credential < ActiveRecord::Base

  belongs_to :user
  belongs_to :business # this is only used to verify uniqueness

  validates :uid, :provider, :user, :business, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => [:business_id], :message => "is already in use for a user" }

  # credentials should never be editable or touched by public-facing controllers...even or admin-facing controllers.
  attr_accessible :user, :business, :uid, :name, :email, :provider, :oauth_token, :oauth_secret, :oauth2_access_token, :oauth2_access_token_expires_at, :oauth2_refresh_token

  before_validation :_copy_business

  scope :with_user, includes(:user)

  def self.new_from_google_oauth2(auth, user)
    Credential.new(:provider => :google_oauth2,
                   :uid => auth[:uid], 
                   :email => auth[:info][:email],
                   :name =>  auth[:info][:name],
                   :oauth2_access_token => auth[:credentials][:token],
                   :oauth2_access_token_expires_at => Time.at(auth[:credentials][:expires_at]),
                   :oauth2_refresh_token => auth[:credentials][:refresh_token],
                   :user => user)
  end

  def _copy_business
    self.business = user.try(:business) if new_record?
  end

end
