require 'spec_helper'

describe StripePaymentGatewayProfile do 

  context "basics" do
    before(:each) { @profile = FactoryGirl.create(:stubbed_client).payment_gateway_profile }
    it "should work with stubs"do
      @profile.should_not be_nil
    end
  end

  context "live", :live_stripe => true do
    before(:each) { @profile = FactoryGirl.create(:stripe_payment_gateway_profile) }

    it "should create in stripe in _create_remote" do
      @profile.vendor_id.should_not == ""
      DetectedError.count.should == 0
    end

    it "should be able to reload remotely with vendor_id, including getting payment profile" do
      token = Stripe::Token.create(:card => {
                                     :number => "4242424242424242",
                                     :exp_month => 3,
                                     :exp_year => Time.now.year + 1,
                                     :cvc => 314
                                   })
      
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
        @profile.card_profile_id.should be_nil
        @profile.card_last_4.should be_nil

        token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 777})
        @profile.update_payment_info(:token => token.id).should be_true

        @profile.card_last_4.should == "4242"
        @profile.card_prompt.should == "Visa ending in 4242"
      end

      it "should be able to update credit card info" do
        token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 777})
        @profile.update_payment_info(:token => token.id).should be_true

        @profile.card_last_4.should == "4242"
        token = Stripe::Token.create(:card => { :number => "4012888888881881", :exp_month => 6, :exp_year => Time.now.year + 2, :cvc => 222})
        @profile.update_payment_info(:token => token.id).should be_true
        @profile.card_last_4.should == "1881"
      end

# card_declined_token = Stripe::Token.create({:card => {:number => "4000000000000002",:exp_month => 4,:exp_year => Time.now.year + 3, :cvc => 777}})


      it "should leave record alone on update failure." do
        token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 777})
        @profile.update_payment_info(:token => token.id).should be_true

        @profile.card_last_4.should == "4242"
        @profile.update_payment_info(:token => 'junk').should be_false
        @profile.errors.full_messages.first.should == I18n.t('payment_gateway_profile.update_error')
        @profile.card_last_4.should == "4242"
        @profile.card_prompt.should == "Visa ending in 4242"
      end

      it "should not populate card info if create fails" do
        @profile.update_payment_info(:token => '13431').should be_false
        @profile.card_last_4.should be_nil
        @profile.card_profile_id.should be_nil
        @profile.card_prompt.should == "No card on file"
        @profile.can_pay?.should be_false
      end      
    end

    context "pay" do
      before(:each) do
        @profile = FactoryGirl.create(:stripe_payment_gateway_profile)
        @invoice = FactoryGirl.create(:pending_invoice, :client => @profile.client)
      end

      it "should fail unless payment info confgured" do
        @profile.pay_invoice!(@invoice).should be_false
        @profile.last_error.should == I18n.t('payment_gateway_profile.cant_pay')
      end

      it "should fail on open invoice" do
        @profile.pay_invoice!(FactoryGirl.create(:invoice)).should be_false
        @profile.last_error.should == I18n.t('payment_gateway_profile.cant_pay')
      end

      it "should be able to pay normal invoice" do
        token = Stripe::Token.create(:card => { :number => "4242424242424242", :exp_month => 3, :exp_year => Time.now.year + 1, :cvc => 777})

        @profile.update_payment_info(:token => token.id).should
        @profile.transactions.count.should == 0
        @invoice.transactions.count.should == 0
        @invoice.paid?.should be_false
        @profile.pay_invoice!(@invoice).should be_true
        @invoice.paid?.should be_true
        @invoice.transactions.count.should == 1
        @profile.transactions.count.should == 1
        @profile.transactions.first.should == @invoice.transactions.first

        @invoice.transactions.first.successful?.should be_true
        @invoice.transactions.first.vendor_id.should_not be_blank
        @invoice.transactions.first.amount.should == @invoice.total

        invoice2 = FactoryGirl.create(:pending_invoice, :client => @profile.client, :total => 1823.34)
        invoice2.transactions.count.should == 0
        @profile.pay_invoice!(invoice2)
        invoice2.transactions.count.should == 1
        invoice2.transactions.first.amount.should == 1823.34
      end

      it "should capture error when transaction fails due to expired card" do
      end
    end
  end

end