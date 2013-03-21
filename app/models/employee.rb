class Employee < ActiveRecord::Base

  belongs_to :business

  has_many :employments, :dependent => :destroy
  has_many :users, :through => :employments

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

end
