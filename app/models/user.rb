class User < ActiveRecord::Base

  has_many :credentials

  has_and_belongs_to_many :clients
  has_and_belongs_to_many :businesses

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

