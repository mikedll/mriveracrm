class Feature < ActiveRecord::Base


  attr_accessible :name, :bit_index

  has_many :feature_selections
  has_many :feature_pricings

  before_validation :_default_public_name

  validates :name, :presence => true, :uniqueness => true
  validates :bit_index, :uniqueness => true
  validate :_never_change_index

  def self.ensure_master_list_created
    them = all

    names = them.map(&:name)
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

  def _default_public_name
    if new_record? && public_name.blank?
      self.public_name = name.titleize
    end
  end

end
