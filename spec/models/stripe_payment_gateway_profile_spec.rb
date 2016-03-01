require 'spec_helper'

describe StripePaymentGatewayProfile do

  context "basics" do
    before(:each) { @profile = FactoryGirl.create(:client).payment_gateway_profile }
    it "should work with stubs"do
      @profile.should_not be_nil
    end
  end

  context "live payment management", :live_stripe => true do
    before(:each) { @profile = FactoryGirl.create(:stripe_payment_gateway_profile) }

    it "should create in stripe in _create_remote" do
      @profile.vendor_id.should_not == ""
      DetectedError.count.should == 0
    end

    it "should be able to reload remotely with vendor_id, including getting payment profile" do
      token = nil
      @profile.send(:_with_stripe_key) do
        token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 314})
      end

      @profile.update_payment_info(:token => token.id).should be_true
      @profile.card_last_4 = ""
      @profile.card_brand = ""
      @profile.save!

      @profile.card_last_4.should == ''
      @profile.card_brand.should == ''
      @profile.reload_remote
      @profile.card_last_4.should == '4242'
      @profile.card_brand.should == 'Visa'
      @profile.card_profile_id.should be_nil # stripe doesnt use an extra id for active card
    end

    context "payment profile" do
      it "should be able to create credit card info" do
        @profile.card_last_4.should == ""
        @profile.card_prompt.should == "No card on file"
        @profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '16', :cv_code => '111').should be_true
        @profile.card_last_4.should == "1881"
        @profile.card_prompt.should == "Visa ending in 1881"
      end

      it "should be able to create credit card info with token instaed of raw data" do
        @profile.card_profile_id.should be_nil
        @profile.card_last_4.should == ""

        token = nil
        @profile.send(:_with_stripe_key) do
          token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 777})
        end

        @profile.update_payment_info(:token => token.id).should be_true

        @profile.card_last_4.should == "4242"
        @profile.card_prompt.should == "Visa ending in 4242"
      end

      it "should be able to update credit card info", :current => true do
        @profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
        @profile.card_last_4.should == "4242"
        @profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '17', :cv_code => '111').should be_true
        @profile.card_last_4.should == "1881"
      end

      it "should leave record alone on update failure.", :current => true do
        @profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
        @profile.card_last_4.should == "4242"
        @profile.update_payment_info({}).should be_false
        @profile.errors.should_not be_empty
        @profile.card_last_4.should == "4242"
        @profile.card_prompt.should == "Visa ending in 4242"
      end

      it "should not populate card info if create fails" do
        @profile.update_payment_info(:token => '13431').should be_false
        @profile.card_last_4.should == ""
        @profile.card_profile_id.should be_nil
        @profile.card_prompt.should == "No card on file"
        @profile.ready_for_payments?.should be_false
      end

      it "should catch credit card errors when updated with raw data instead of token" do
        @profile.card_last_4.should == ""
        @profile.card_prompt.should == "No card on file"
        @profile.update_payment_info(:card_number => '4012888888881881', :expiration_month => '08', :expiration_year => '11', :cv_code => '111').should be_false
        @profile.errors.full_messages.should == ['Expiration year expired']
        @profile.card_last_4.should == ""
        @profile.card_prompt.should == "No card on file"
      end
    end
  end

  context "live pay", :live_stripe => true do
    before(:each) do
      @profile = FactoryGirl.create(:stripe_payment_gateway_profile)
      @invoice = FactoryGirl.create(:pending_invoice, :client => @profile.payment_gateway_profilable)
    end

    it "should fail unless payment info confgured", :current => true do
      @invoice.charge!.should be_false
      @profile.last_error.to_s.should == I18n.t('payment_gateway_profile.not_ready_for_payments')
    end

    it "should fail on open invoice", :current => true do
      @invoice.charge!.should be_false
      @profile.last_error.to_s.should == I18n.t('payment_gateway_profile.not_ready_for_payments')
    end

    it "should be able to pay normal invoice", :current => true do
      @profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
      @profile.transactions.count.should == 0
      @invoice.transactions.count.should == 0
      @invoice.paid?.should be_false
      @invoice.charge!.should be_true
      @profile.reload
      @profile.last_error.should be_nil
      @invoice.paid?.should be_true
      @invoice.transactions.count.should == 1
      @profile.transactions.count.should == 1
      @profile.transactions.first.should == @invoice.transactions.first

      @invoice.transactions.first.successful?.should be_true
      @invoice.transactions.first.vendor_id.should_not be_blank
      @invoice.transactions.first.amount.should == @invoice.total

      invoice2 = FactoryGirl.create(:pending_invoice, :client => @profile.payment_gateway_profilable, :total => 1823.34)
      invoice2.transactions.count.should == 0
      @profile.pay_invoice!(invoice2)
      invoice2.transactions.count.should == 1
      invoice2.transactions.first.amount.should == 1823.34
    end

    it "should capture error when transaction fails due to declined card", :current => true do
      @profile.update_payment_info(:card_number => '4000000000000341', :expiration_month => '03', :expiration_year => '17', :cv_code => '111').should be_true
      @profile.transactions.count.should == 0
      @invoice.paid?.should be_false
      @invoice.charge! be_false
      @profile.transactions.count.should == 1
      @profile.transactions.first.should == @invoice.transactions.first
      @invoice.transactions.first.failed?.should be_true
      @invoice.failed_payment?.should be_true
      @profile.last_error.should == 'Your card was declined.'
    end
  end

  context "live plan updates", :live_stripe => true do
    before do
      fs = Feature.all
      @f1 = fs[0]
      @f2 = fs[1]

      Feature.ensure_minimal_pricings!
      @profile = FactoryGirl.create(:stripe_payment_gateway_profile_for_us)
      @us = @profile.payment_gateway_profilable

      fs[0,2].each { |f| FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => f) }
      @us.reload
    end

    it "should be able to create a usage subscription's plan" do
      @profile.ensure_plan_created!(@us.calculated_plan_id, @us.calculated_price).should be_true
    end

    it "should be able to update a plan and have it update usage subscription", :current2 => true do
      before = @profile.stripe_plan
      expected_plan = @us.calculated_plan_id
      @profile.ensure_plan_created!(@us.calculated_plan_id, @us.calculated_price).should be_true
      @us.payment_gateway_profile.update_plan!(@us.calculated_plan_id, @us).should be_true
      @profile.reload
      @profile.stripe_plan.should_not == before
      @profile.stripe_plan.should == expected_plan
      @profile.remote_status.should == @profile.stripe_status
      @profile.remote_status.should == PaymentGatewayProfile::Status::TRIALING
    end
  end

end
