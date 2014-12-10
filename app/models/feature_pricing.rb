class FeaturePricing < ActiveRecord::Base

  DEFAULT = BigDecimal.new("5.00")

  belongs_to :feature

  validates :feature_id, :presence => true
  validates :price, :presence => true
  validates :generation, :presence => true

  scope :for_generation, lambda { |g| where('generation = ?', g) }
  scope :generation_ordered, lambda { order('generation') }
  scope :price_ordered, lambda { order('price') }
end
