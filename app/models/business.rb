class Business < ActiveRecord::Base

  has_many :clients, :dependent => :destroy

  has_many :invitations, :dependent => :destroy

end
