class MarketingFrontEnd < ActiveRecord::Base

  has_many :businesses, :foreign_key => :default_mfe_id

  cattr_accessor :current

end
