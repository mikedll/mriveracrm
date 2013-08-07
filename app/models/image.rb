class Image < ActiveRecord::Base

  belongs_to :business
  belongs_to :project

  has_many :product_images
  has_many :products, :through => :product_images

  mount_uploader :data, ImageUploader

end
