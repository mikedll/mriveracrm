class Letter < ActiveRecord::Base

  include Introspectable

  belongs_to :business
  validates :business_id, :presence => true
  validates :title, :presence => true

  attr_accessible :title, :body

  introspect do
    nested_association :preview

    attr :title
    attr :body
    fmore :as => :text
  end
end
