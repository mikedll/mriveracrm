class Employment < ActiceRecord::Base

  belongs_to :business_id
  belongs_to :employee
  belongs_to :user

  validates :user_id, :uniqueness => { :scope => :business_id }

end

