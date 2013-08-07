class ProductImage < ActiveRecord::Base

  belongs_to :product
  belongs_to :image

  attr_accessible :active, :primary

  scope :primary, where('product_images.primary = ?', true)

end
