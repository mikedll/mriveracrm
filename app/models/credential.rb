class Credential < ActiveRecord::Base

  belongs_to :user

  validates :uid, :provider, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }

  attr_accessible :uid, :name, :email, :provider, :oauth_token, :oauth_secret, :oauth2_access_token, :oauth2_access_token_expires_at, :oauth2_refresh_token

  scope :with_user, includes(:user)
end
