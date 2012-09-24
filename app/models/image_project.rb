class ImageProject < ActiveRecord::Base
  belongs_to :image
  belongs_to :project
end

