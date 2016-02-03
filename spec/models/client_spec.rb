
require 'spec_helper'

describe Client do
  context "validations" do
    it "should validate email" do
      b = FactoryGirl.create(:business)
      client = FactoryGirl.create(:stubbed_client, :business => b)
      client.email = "asdf"
      client.save.should be_false
      client.email = ""
      client.save.should be_true
      client.email = "a@b.com"
      client.save.should be_true

      client2 = FactoryGirl.create(:stubbed_client, :business => b)
      client2.email = "a@b.com"
      client2.save.should be_false
    end
  end

  context "inactive expiry", :live_stripe => true, :current => true do
    before do
      @client = FactoryGirl.create(:client)
    end

    it "should erase card information and the user" do
      @client.payment_gateway_profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '16', :cv_code => '111').should be_true

      @client.payment_gateway_profile.reload
      @client.payment_gateway_profile.card_last_4.blank?.should be_false
      @client.expire_user!
      @client.payment_gateway_profile.reload
      @client.payment_gateway_profile.card_last_4.blank?.should be_true
    end
  end
end
