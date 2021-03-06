class Feature < ActiveRecord::Base

  attr_accessible :name, :bit_index, :public_name

  has_many :feature_selections, :dependent => :destroy
  has_many :feature_pricings, :dependent => :destroy
  has_many :feature_provision, :dependent => :destroy

  before_validation :_default_public_name

  validates :name, :presence => true, :uniqueness => true
  validates :bit_index, :uniqueness => true
  validate :_never_change_index

  scope :bit_index_ordered, lambda { order('bit_index') }

  module Names
    CLIENTS = 'clients'
    EMPLOYEES = 'employees'
    INVOICING = 'invoicing'
    PRODUCTS = 'products'
    APPS_FRAMEWORK = 'apps_framework'
    IT_MONITORED_COMPUTERS = 'it_monitored_computers'
    CMS = 'cms'
  end

  # This is the master list of features. This
  # derives the bit index.
  ALL = [
    Names::CLIENTS,
    Names::EMPLOYEES,
    Names::INVOICING,
    Names::PRODUCTS,
    Names::APPS_FRAMEWORK,
    Names::IT_MONITORED_COMPUTERS,
    Names::CMS
  ]

  def self.first_generation_price(name)
    p = {
      Names::CLIENTS => BigDecimal("10.0"),
      Names::EMPLOYEES => BigDecimal("0.0"),
      Names::INVOICING => BigDecimal("10.0"),
      Names::PRODUCTS => BigDecimal("5.0"),
      Names::APPS_FRAMEWORK => BigDecimal("5.0"),
      Names::IT_MONITORED_COMPUTERS => BigDecimal("10.0"),
      Names::CMS => BigDecimal("10.0")
    }[name]

    raise "No first generation price for #{name}." if p.nil?

    p
  end


  def self.ensure_minimal_pricings!
    Feature.all.each {  |f| f.ensure_generation_pricing! }
  end

  def self.ensure_master_list_created!
    them = all

    names = them.map(&:name)
    ALL.each_with_index do |n, i|
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
      fp = FeaturePricing.create!(:generation => generation, :price => (last_gen ? last_gen.price : self.class.first_generation_price(name)), :feature => self)
    end
  end

  def as_json_public
    as_json(:only => [:created_at, :public_name, :name, :bit_index])
  end

  protected

  def _never_change_index
    if !new_record? && bit_index_changed?
      errors[:bit_index] = I18n.t('feature_pricing.cant_change_index')
    end
  end

  def _default_public_name
    if new_record? && public_name.blank?
      self.public_name = name.titleize
    end
  end

end
