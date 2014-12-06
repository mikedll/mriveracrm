require 'spec_helper'

describe FeatureSelection do
  context "validations"  do

    before do
      @us = FactoryGirl.create(:usage_subscription)
    end

    it "should not allow dup features" do
      p = FactoryGirl.create(:feature_pricing)
      fs1 = FactoryGirl.build(:feature_selection, :feature => p.feature, :usage_subscription => @us)
      fsdup = FactoryGirl.build(:feature_selection, :feature => p.feature, :usage_subscription => @us)
      fs1.save.should be_true
      fsdup.save.should be_false
      fsdup.errors[:feature_id].should =~ [I18n.t('errors.messages.taken')]
    end
  end

end
