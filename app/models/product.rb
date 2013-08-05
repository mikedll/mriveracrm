class Product < ActiveRecord::Base

  belongs_to :business
  has_and_belongs_to_many :general_images

  attr_accessible :name, :price

end
