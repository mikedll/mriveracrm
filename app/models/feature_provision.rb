class FeatureProvision < ActiveRecord::Base

  belongs_to :marketing_front_end, :inverse_of => :feature_provision
  belongs_to :feature, :inverse_of => :feature_provision

  validates :feature_id, :presence => true, :uniqueness => { :scope => :marketing_front_end_id }
  validates :marketing_front_end_id, :presence => true

end
