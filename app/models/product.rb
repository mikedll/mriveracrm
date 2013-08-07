class Product < ActiveRecord::Base

  belongs_to :business

  has_many :product_images
  has_many :images, :through => :product_images

  attr_accessible :name, :price, :active

end
