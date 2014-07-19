class FeaturePricing < ActiveRecord::Base
  attr_accessible :feature_name, :price, :release, :index

  validates :price, :presence => true
  validates :generation, :presence => true
  validates :feature_name, :presence => true
  validates :index, :uniqueness => true
end
