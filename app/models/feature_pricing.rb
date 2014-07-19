class FeaturePricing < ActiveRecord::Base
  attr_accessible :feature_name, :price, :release, :index

  validates :price, :presence => true
  validates :generation, :presence => true
  validates :feature_name, :presence => true
  validates :index, :uniqueness => true
  validate :_never_change_index

  def _never_change_index
    if !new_record? && changed?(:index)
      errors[:index] = I18n.t('feature_pricing.cant_change_index')
    end
  end

end
