class Notification < ActiveRecord::Base
  belongs_to :business, :inverse_of => :notifications
end
