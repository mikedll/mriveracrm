class Image < ActiveRecord::Base

  belongs_to :business
  belongs_to :project

  has_and_belongs_to_many :products

  mount_uploader :data, ImageUploader

end
