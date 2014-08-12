class FeatureSelection < ActiveRecord::Base
  belongs_to :usage_subscription, :inverse_of => :feature_selections
  belongs_to :feature, :inverse_of => :feature_selections

  validates :feature_id, :presence => true
  validates :usage_subscription_id, :presence => true, :uniqueness => { :scope => :usage_subscription_id }

end
