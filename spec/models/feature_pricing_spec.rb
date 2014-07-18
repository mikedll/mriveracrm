require 'spec_helper'

describe FeaturePricing do
  it "should require a price" do
    @fp = FactoryGirl.create(:feature_pricing)
    @fp.valid?.should be_true
  end
end
