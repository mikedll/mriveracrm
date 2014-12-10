class Feature < ActiveRecord::Base


  attr_accessible :name, :bit_index, :public_name

  has_many :feature_selections, :dependent => :destroy
  has_many :feature_pricings, :dependent => :destroy

  before_validation :_default_public_name

  validates :name, :presence => true, :uniqueness => true
  validates :bit_index, :uniqueness => true
  validate :_never_change_index

  scope :bit_index_ordered, lambda { order('bit_index') }

  def self.ensure_minimal_pricings!
    Feature.all.each {  |f| f.ensure_generation_pricing! }
  end

  def self.ensure_master_list_created!
    them = all

    names = them.map(&:name)
    MasterFeatureList::ALL.each_with_index do |n, i|
      if !names.include?(n)
        f = create(:name => n, :bit_index => i, :public_name => n.titleize)
        them.push(f)
      end
    end

    them.sort! { |a,b| a.bit_index <=> b.bit_index }
    them
  end

  def ensure_generation_pricing!(generation = 0)
    if feature_pricings.for_generation(generation).first.nil?
      last_gen = feature_pricings.generation_ordered.last
      fp = FeaturePricing.create!(:generation => generation, :price => (last_gen ? last_gen.price : FeaturePricing::DEFAULT), :feature => self)
    end
  end

  def as_json_public
    as_json(:only => [:created_at, :public_name, :name, :bit_index])
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
