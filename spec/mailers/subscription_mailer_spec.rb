require "spec_helper"

describe SubscriptionMailer do

  it "should include timezone in introductory email" do
    Timecop.freeze(Time.parse("2014-12-20 03:36:40 -0800")) do
      @us = FactoryGirl.create(:usage_subscription)
      @us.reload
      SubscriptionMailer.welcome(@us).deliver!
      e = ActionMailer::Base.deliveries.last
      e.body.should match Regexp.quote("January 19, 2015  3:36am PST")
    end
  end
end
