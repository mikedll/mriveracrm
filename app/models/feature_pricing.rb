class FeaturePricing < ActiveRecord::Base
  belongs_to :feature

  validates :feature_id, :presence => true
  validates :price, :presence => true
  validates :generation, :presence => true

end
