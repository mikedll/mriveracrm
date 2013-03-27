class Project < ActiveRecord::Base

  belongs_to :business
  has_many :images

end

