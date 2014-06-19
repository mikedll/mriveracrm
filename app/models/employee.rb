class Employee < ActiveRecord::Base

  belongs_to :business

  has_one :user
  has_many :invitations

  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

  scope :cb, lambda { where('employees.business_id = ?', Business.current.try(:id)) }
  scope :is_owner, lambda { where('employees.role = ?', Roles::OWNER) }

  module Roles
    OWNER = 'owner'
  end
end
