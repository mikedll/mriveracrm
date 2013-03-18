class Client < ActiveRecord::Base

  has_and_belongs_to_many :businesses
  has_and_belongs_to_many :users
  has_many :invitations

  has_one :authorize_net_customer_profile

end
