class GeneralImage < ActiveRecord::Base

  belongs_to :business
  has_and_belongs_to_many :products

  mount_uploader :data, ImageUploader

  attr_accessible :data

end
