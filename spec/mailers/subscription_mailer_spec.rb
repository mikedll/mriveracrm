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


  it "should provide appropriate home URL, mfe or host style" do
    @business = FactoryGirl.create(:business, :host => "")
    SubscriptionMailer.welcome(@business.usage_subscription).deliver!
    e = ActionMailer::Base.deliveries.last
    e.body.should match Regexp.quote("#{@business.default_mfe.host}/b/#{@business.handle}")

    ActionMailer::Base.deliveries = []
    @business.host = "www.#{@business.handle}.com"
    @business.save!
    @business.usage_subscription.reload
    SubscriptionMailer.welcome(@business.usage_subscription).deliver!
    e = ActionMailer::Base.deliveries.last
    e.body.should_not match Regexp.quote("#{@business.default_mfe.host}/b/#{@business.handle}")
    e.body.should match Regexp.quote("#{@business.host}")
  end


end
