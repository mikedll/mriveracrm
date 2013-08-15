class Product < ActiveRecord::Base

  belongs_to :business

  has_many :product_images, :dependent => :destroy
  has_many :images, :through => :product_images

  attr_accessible :name, :price, :weight, :active, :weight_units, :description

  def self.search(query)
    where('UPPER(products.name) LIKE (?)', "%#{query}%")
  end

end
