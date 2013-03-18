require 'spec_helper'

describe AuthorizeNetPaymentGatewayProfile do 

  context "basics" do
    before(:each) { @profile = FactoryGirl.create(:stubbed_authorize_net_payment_gateway_profile) }
    it "should work with stubs"do
      @profile.should_not be_nil
    end
  end

  context "live", :live_authorizenet => true do
    before(:each) { @profile = FactoryGirl.create(:authorize_net_payment_gateway_profile) }

    it "should create in authorize.net in _create_remote" do
      @profile.vendor_id.should_not == ""
      DetectedError.count.should == 0
    end

    it "should be able to reload remotely with vendor_id, including getting payment profile", :current => true do
        @profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true
        @profile.card_last_4 = ""
        before = @profile.card_profile_id
        @profile.card_profile_id = nil
        @profile.save!

        @profile.card_last_4.should == ''
        @profile.card_profile_id.should be_nil
        @profile.reload_remote
        @profile.card_last_4.should == '2222'
        @profile.card_profile_id.should == before
    end

    context "payment profile" do
      it "should be able to create credit card info" do
        @profile.card_profile_id.should be_nil
        @profile.card_last_4.should be_nil

        @profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true

        @profile.card_profile_id.should_not be_nil
        @profile.card_last_4.should == "2222"
        @profile.card_prompt.should == "Card ending in 2222"
      end

      it "should be able to update credit card info" do
        @profile.update_payment_info(:card_number => '4222222222221', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true

        @profile.card_profile_id.should_not be_nil
        @profile.card_last_4.should == "2221"
        @profile.update_payment_info(:card_number => '4222222222222', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true
        @profile.card_last_4.should == "2222"
      end

      it "should leave record on update failure" do
        @profile.update_payment_info(:card_number => '4222222222221', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_true

        @profile.card_profile_id.should_not be_nil
        @profile.card_last_4.should == "2221"
        @profile.update_payment_info(:card_number => 'junk', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_false
        
        @profile.errors.full_messages.first.should match(Regexp.new(I18n.t('payment_gateway_profile.update_error')))
        @profile.card_last_4.should == "2221"
        @profile.card_prompt.should == "Card ending in 2221"
      end

      it "should not create card profile if create fails" do
        @profile.update_payment_info(:card_number => 'junk', :expiration_month => '08', :expiration_year => '2016', :card_code => '111').should be_false
        @profile.card_last_4.should be_nil
        @profile.card_profile_id.should be_nil
        @profile.card_prompt.should == "No card on file"
      end      
     end
  end

end
