require 'spec_helper'

describe FeatureSelection do
  context "validations" do
    it "should not allow dup features" do
      @us = FactoryGirl.create(:usage_subscription)
      p = FactoryGirl.create(:feature_pricing)
      fs1 = FactoryGirl.build(:feature_selection, :feature_pricing => p, :usage_subscription => @us)
      fsdup = FactoryGirl.build(:feature_selection, :feature_pricing => p, :usage_subscription => @us)
      fs1.save.should be_true
      fsdup.save.should be_false
      fsdup.errors[:feature_pricing_id].should_not be_empty
    end
  end
end
