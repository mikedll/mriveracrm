class Client < ActiveRecord::Base

  belongs_to :business
  has_many :contact_relationships, :dependent => :destroy
  has_many :users, :through => :contact_relationships

  has_many :invitations
  has_many :invoices
  has_one :authorize_net_customer_profile


  attr_accessible :first_name, :last_name, :email

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

end
