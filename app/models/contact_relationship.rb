class ContactRelationship < ActiveRecord::Base

  belongs_to :business
  belongs_to :client
  belongs_to :user

  validates :user_id, :uniqueness => { :scope => :business_id }

end
