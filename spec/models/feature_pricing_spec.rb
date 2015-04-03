require 'spec_helper'

describe FeaturePricing do
  it "should require a price" do
    @fp = FactoryGirl.create(:feature_pricing)
    @fp.valid?.should be_true
  end

  it "should be able to draw first gen pricing" do
    f = FactoryGirl.create(:feature)
    f.ensure_generation_pricing!
    fp = f.feature_pricings.first
  end
end
