class Feature < ActiveRecord::Base

  ALL = [
    ['clients', "Client Manager"],
    ['employees', "Multiple Employees"],
    ['invoicing', "Client Invoicing"],
    ['products', 'Products Showcase']
  ]

  attr_accessible :feature_name, :bit_index

  has_many :feature_selections
  has_many :feature_pricings

  validates :feature_name, :presence => true, :uniqueness => true
  validates :bit_index, :uniqueness => true
  validate :_never_change_index

  def _never_change_index
    if !new_record? && changed?(:bit_index)
      errors[:bit_index] = I18n.t('feature_pricing.cant_change_index')
    end
  end

end
