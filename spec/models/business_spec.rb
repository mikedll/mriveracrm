
require 'spec_helper'

describe Business do

  context "validations" do
    before do
      @business = FactoryGirl.create(:business)
    end

    it "should require unique handle" do
      b2 = FactoryGirl.build(:business, :handle => @business.handle)
      b2.save.should be_false
      b2.errors[:handle].should == ['has already been taken']
    end

    it "should downcase and trim the handle" do
      b2 = FactoryGirl.create(:business, :handle => " CHAOS9 ")
      b2.reload
      b2.handle.should == "chaos9"
    end

    it "should validate format of handle" do
      ["chaos 9", "chao*s9"].map { |h| FactoryGirl.build(:business, :handle => h) }.each do |b|
        b.save.should be_false
        b.errors[:handle].should =~ [I18n.t('business.errors.handle_format')]
      end
    end

    it "should not allow conflict with mfe" do
      mfe = FactoryGirl.create(:marketing_front_end)
      d = FactoryGirl.build(:business, :host => mfe.host)
      d.save.should be_false
      d.errors[:host].should =~ [I18n.t('business.mfe_host_conflict')]
      d.host = FactoryGirl.build(:business).host
      d.save.should be_true
    end

    it "should validate host" do
      @business.host = "WWWdddcom"
      @business.save.should be_false
      @business.errors['host'].should_not be_empty

      @business.host = "www.validchar&(*.com"
      @business.save.should be_false
      @business.errors['host'].should_not be_empty

      @business.host = "333-444-9999"
      @business.save.should be_false
      @business.errors['host'].should_not be_empty

      @business.host = "www.we-are-great.com"
      @business.save.should be_true
    end

    it "should format host" do
      @business.host = "WWW.ddd.com"
      @business.save.should be_true
      @business.host.should == "www.ddd.com"
    end

  end

  it "scopes" do
    b = FactoryGirl.create(:business)
    b = Business.with_features.find_by_id b.id
    b.should_not be_nil
  end

  context "expiring inactive clients" do
    it "should eliminate users and payment information" do
      reftime = Time.now
      @client = FactoryGirl.create(:client_user, :reftime => reftime - 25.hours).client
      @client.payment_gateway_profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true

      @client2 = FactoryGirl.create(:client_user).client
      @client2.payment_gateway_profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true

      @client.payment_gateway_profile.reload
      @client.payment_gateway_profile.card_last_4.blank?.should be_false
      Timecop.freeze(reftime + 29.days) do
        Business.expire_client_information_when_dormant!

        @client.payment_gateway_profile.reload
        @client.payment_gateway_profile.card_last_4.blank?.should be_true
        @client.reload
        @client.users.count.should == 0

        @client2.payment_gateway_profile.reload
        @client2.payment_gateway_profile.card_last_4.blank?.should be_false
        @client2.reload
        @client2.users.count.should == 1
      end
    end

    context "dormant payment information", :current => true do
      it "should be erased" do
        reftime = Time.now

        # Will stay due to old card but recent transaction
        c = FactoryGirl.create(:client)

        # Will be deleted to to old card and no recent transaction
        c2 = FactoryGirl.create(:client)

        # Will stay due to recently updated card information
        c3 = FactoryGirl.create(:client)

        Timecop.freeze(reftime - 45.days) do
          c.payment_gateway_profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
        end

        Timecop.freeze(reftime - 45.days) do
          c2.payment_gateway_profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
        end

        Timecop.freeze(reftime - 15.days) do
          c3.payment_gateway_profile.update_payment_info(SpecSupport.valid_stripe_cc_params).should be_true
        end

        Timecop.freeze(reftime - 15.days) do
          i1 = FactoryGirl.create(:pending_invoice, :client => c)
          FactoryGirl.create(:paid_stripe_transaction, :invoice => i1)
        end

        Timecop.freeze(reftime - 45.days) do
          i2 = FactoryGirl.create(:pending_invoice, :client => c2)
          FactoryGirl.create(:paid_stripe_transaction, :invoice => i2)
        end

        Business.expire_client_information_when_dormant!

        c.reload
        c.payment_gateway_profile.card_last_4.blank?.should be_false

        c2.reload
        c2.payment_gateway_profile.card_last_4.blank?.should be_true

        c3.reload
        c3.payment_gateway_profile.card_last_4.blank?.should be_false
      end
    end
  end
end
