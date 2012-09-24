class Image < ActiveRecord::Base

  has_many :image_projects
  has_many :projects, :through => :image_project

  mount_uploader :data, PortfolioImageUploader

end
