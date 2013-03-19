class Business < ActiveRecord::Base

  has_many :clients, :dependent => :destroy
  has_and_belongs_to_many :users

  has_many :invitations, :dependent => :destroy

end
