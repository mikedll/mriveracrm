class User < ActiveRecord::Base

  has_many :credentials

  devise :omniauthable

  before_validation :_default_timezone, :if => :new_record?

  def _default_timezone
    timezone = 'Pacific Time (US & Canada)' if timezone.nil?
  end
  
end

