class ProductImage < ActiveRecord::Base

  belongs_to :product
  belongs_to :image

  attr_accessible :active

end
