class FeatureSelection < ActiveRecord::Base
  belongs_to :usage_subscription
  belongs_to :feature

  validates :feature_id, :presence => true
  validates :usage_subscription_id, :presence => true, :uniqueness => { :scope => :usage_subscription_id }

end
