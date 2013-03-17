class Business < ActiveRecord::Base

  has_and_belongs_to_many :clients
  has_and_belongs_to_many :users

  has_many :invitations, :dependent => :destroy

end
