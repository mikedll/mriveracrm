class User < ActiveRecord::Base

  has_many :credentials

  has_many :contact_relationships
  has_many :clients, :through => :contact_relationships

  has_many :employments
  has_many :business, :through => :employments

  devise :omniauthable

  before_validation :_default_timezone, :if => :new_record?

  def client
    clients.first
  end

  def business
    businesses.first
  end

  def _default_timezone
    timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end
  
end

