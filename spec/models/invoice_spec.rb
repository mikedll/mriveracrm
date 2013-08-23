
require 'spec_helper'

describe Invoice do
  context "basics" do
    before(:each) { @invoice = FactoryGirl.create(:invoice) }

    it "should error out on charge! if invoice is open or paid" do
      @invoice.charge!
      @invoice.errors.full_messages.should == [I18n.t('invoice.cannot_pay')]
    end

    it "should not allow changes after leaving open state" do
      @invoice.mark_pending!
      @invoice.total = 12.00
      @invoice.save.should be_false
      @invoice.errors.full_messages.should == [I18n.t('invoice.uneditable')]

      FactoryGirl.create(:paid_stripe_transaction, :invoice => @invoice)
      @invoice.reload
      @invoice.mark_paid!
      @invoice.description = "asdfsdfasfsdfsdfasfsfds"
      @invoice.save.should be_false

      @invoice.errors.full_messages.should == [I18n.t('invoice.uneditable')]
    end
  end

  context "scopes" do
    it "should not allow cancelled or open invoices to be shown to user." do
      invoice = FactoryGirl.create(:invoice, :status => :open)
      Invoice.count.should == 1
      Invoice.viewable_to_client.count.should == 0

      invoice = FactoryGirl.create(:invoice, :status => :cancelled)
      Invoice.count.should == 2
      Invoice.viewable_to_client.count.should == 0

      invoice = FactoryGirl.create(:invoice, :status => :pending)
      Invoice.viewable_to_client.count.should == 1

      invoice.cancel!.should be_true
      Invoice.count.should == 3
      Invoice.viewable_to_client.count.should == 0


      FactoryGirl.create(:invoice, :status => :pending)
      FactoryGirl.create(:invoice, :status => :failed_payment)
      FactoryGirl.create(:invoice, :status => :paid)
      FactoryGirl.create(:invoice, :status => :closed)
      Invoice.count.should == 7
      Invoice.viewable_to_client.count.should == 4
    end
  end

  context "cancel" do
    it "should only work for pending invoices" do
      invoice = FactoryGirl.create(:invoice, :status => :pending)
      invoice.cancel!.should be_true
      invoice.cancelled?.should be_true
      
      invoice = FactoryGirl.create(:invoice, :status => :open)
      expect { invoice.cancel! }.to raise_error(StateMachine::InvalidTransition)
    end
  end

  context "destroy" do
    before(:each) { @invoice = FactoryGirl.create(:invoice) }

    it "should work for open and fail for invoices past open state" do
      id = @invoice.id
      @invoice.destroy
      (Invoice.find_by_id id).should be_nil
    end

    it "should fail for invoices past open state" do
      id = @invoice.id
      @invoice.mark_pending!
      @invoice.destroy
      (Invoice.find_by_id id).should_not be_nil
      @invoice.errors.full_messages.should == [I18n.t('invoice.cannot_delete')]
    end
  end

  context "typical pay cycle" do
    it "should allow basic payable transactions under normal operations" do
      i = FactoryGirl.create(:unstubbed_client_invoice)
      i.mark_pending!
      i.client.payment_gateway_profile.update_payment_info(:card_number => '4242424242424242', :expiration_month => '03', :expiration_year => '15', :cv_code => '111').should be_true
      i.charge!.should be_true
    end
  end

  context "mark_paid", :current => true do
    it "should fail if invoice doesnt have a successful transaction" do
      invoice = FactoryGirl.create(:invoice)
      invoice.mark_pending!

      invoice.mark_paid.should be_false

      t = FactoryGirl.create(:outside_transaction, :invoice => invoice)
      t.begin!
      t.succeed!

      invoice.mark_paid.should be_true
    end
  end

  context "pdf_gen", :current => true do
    it "should generate pdf" do
      invoice = FactoryGirl.create(:pending_invoice)      
      invoice.generate_pdf

    end    
  end

end
