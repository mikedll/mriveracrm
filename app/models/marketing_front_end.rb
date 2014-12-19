class MarketingFrontEnd < ActiveRecord::Base

  has_many :businesses, :foreign_key => :default_mfe_id
  has_many :feature_provisions
  has_many :features, :through => :feature_provisions

  cattr_accessor :current

end
