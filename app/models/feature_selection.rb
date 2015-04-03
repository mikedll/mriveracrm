class FeatureSelection < ActiveRecord::Base
  belongs_to :usage_subscription, :inverse_of => :feature_selections
  belongs_to :feature, :inverse_of => :feature_selections

  validates :feature_id, :presence => true, :uniqueness => { :scope => :usage_subscription_id }
  validates :usage_subscription_id, :presence => true

  scope :bit_index_ordered, lambda { joins(:feature).order('features.bit_index') }

end
