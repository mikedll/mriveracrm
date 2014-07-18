require 'spec_helper'

describe UsageSubscription do
  context "validations" do
    it "should require business" do
      @us = FactoryGirl.create(:usage_subscription)
      @us.business = nil
      @us.save.should be_true
    end
  end
end
