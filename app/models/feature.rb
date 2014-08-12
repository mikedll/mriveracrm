class Feature < ActiveRecord::Base


  attr_accessible :feature_name, :bit_index

  has_many :feature_selections
  has_many :feature_pricings

  before_validation :_default_pretty_name

  validates :name, :presence => true, :uniqueness => true
  validates :bit_index, :uniqueness => true
  validate :_never_change_index

  def self.load_master
    them = all

    names = them.map(:name)
    MasterFeatureList::ALL.each_with_index do |n, i|
      if !names.include?(n)
        f = create(:name => n, :bit_index => i)
        them.push(f)
      end
    end

    them.sort! { |a,b| a.bit_index <=> b.bit_index }
    them
  end

  protected

  def _never_change_index
    if !new_record? && changed?(:bit_index)
      errors[:bit_index] = I18n.t('feature_pricing.cant_change_index')
    end
  end

  def _default_pretty_name
    if new_record? && pretty_name.blank?
      self.pretty_name = name.titleize
    end
  end

end
