
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

  context "scopes" do
    it "should recognize clients without an active user" do
      @user = FactoryGirl.create(:client_user)
      @user.last_sign_in_at = Time.now - 5.minutes
      @user.save!

      Timecop.freeze(Time.now + 30.days) do
        clients = Client.without_active_users
        clients.first.should == @user.client
      end

      Timecop.freeze(Time.now + 29.days) do
        clients = Client.without_active_users
        clients.first.should be_nil
      end
    end

    it "should recognize theoretically active payment information" do
      @client = FactoryGirl.create(:client)
      Client.with_active_card_info.first.should be_nil
      @client.payment_gateway_profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '16', :cv_code => '111').should be_true
      Client.with_active_card_info.first.should == @client
    end
  end

  context "inactive expiry" do
    before do
      @client = FactoryGirl.create(:client)
    end

    context "with respect to payment gateway profile", :live_stripe => true do
      it "should erase card information" do
        @client.payment_gateway_profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '16', :cv_code => '111').should be_true

        @client.payment_gateway_profile.reload
        @client.payment_gateway_profile.card_last_4.blank?.should be_false
        @client.handle_inactive!
        @client.payment_gateway_profile.card_last_4.blank?.should be_true
      end
    end

    it "should erase the inactive user", :current => true do
      raise "help"
    end
  end
end
