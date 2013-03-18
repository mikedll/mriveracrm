require 'spec_helper'

describe AuthorizeNetPaymentGatewayProfile do 

  context "basics" do
    before(:each) { @profile = FactoryGirl.create(:stubbed_authorize_net_payment_gateway_profile) }
    it "should work with stubs"do
      @profile.should_not be_nil
    end
  end

  context "live", :live_authorizenet => true, :current => true do
    before(:each) { @profile = FactoryGirl.create(:authorize_net_payment_gateway_profile) }

    it "should create in authorize.net in _create_remote" do
      @profile.vendor_id.should_not == ""
      DetectedError.count.should == 0
    end

    it "should be able to update credit card info" do
      @profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true
      @profile.reload_remote
      @profile.card_last_4.should == "2222"
    end
  end

end
