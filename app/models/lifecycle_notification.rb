class LifecycleNotification < ActiveRecord::Base

  belongs_to :business

  validates :identifier, :uniqueness => { :scope => :business_id }
  validates :business_id, :presence => true

  scope :by_identifier, lambda { |id| where('identifier = ?', id) }

  attr_accessible :identifier, :body

  module Common
    WELCOME = 'welcome'
  end
end
