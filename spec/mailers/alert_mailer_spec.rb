
require 'spec_helper'

describe AlertMailer do
  it "should use default mfe in signature" do
    b = FactoryGirl.create(:business)
    mc = FactoryGirl.create(:dead_it_monitored_computer, :business => b)
    AlertMailer.computer_down(b, mc).deliver!
    m = ActionMailer::Base.deliveries.last
    m.body.should include("#{b.default_mfe.title} Automatic Alert Service")
  end
end
