class Client < ActiveRecord::Base

  belongs_to :business
  has_and_belongs_to_many :users
  has_many :invitations
  has_many :invoices
  has_one :authorize_net_customer_profile

  attr_accessible :first_name, :last_name, :email

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

end
