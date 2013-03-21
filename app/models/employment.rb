class Employment < ActiveRecord::Base

  belongs_to :business
  belongs_to :employee
  belongs_to :user

  validates :user_id, :uniqueness => { :scope => :business_id }

end

