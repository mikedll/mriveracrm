class Product < ActiveRecord::Base

  belongs_to :business

  has_many :product_images, :dependent => :destroy
  has_many :images, :through => :product_images

  attr_accessible :name, :price, :weight, :active, :weight_units, :description

  scope :active, where('active = ?', true)
  scope :max_price, lambda { |p| where('price is null or price <= ?', p) }
  scope :string_search, lambda { |s| where('UPPER(products.name) LIKE ?', "%#{s.upcase}%") }
  scope :cb, -> { where('products.business_id = ?', Business.current.try(:id)) }

  def self.index_or_search(params)
    query = self.active
    query = query.string_search(params[:query]) if !params[:query].blank?
    query = query.max_price(params[:max_price]) if !params[:max_price].blank?
    query
  end

  def primary_product_image
    self.product_images.primary.first
  end


end
