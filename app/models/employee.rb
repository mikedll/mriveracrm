class Employee < ActiceRecord::Base

  belongs_to :business_id

  has_many :employments
  has_many :users, :through => :employments

  validates :user_id, :uniqueness => { :scope => :business_id }

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

end
