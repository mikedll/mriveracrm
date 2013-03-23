
require 'spec_helper'

describe Invoice do
  context "basics" do
    before(:each) { @invoice = FactoryGirl.create(:invoice) }
    it "should error out on charge! if invoice is open or paid", :current => true do
      @invoice.charge!
      @invoice.errors.full_messages.should == [I18n.t('invoice.cannot_pay')]
    end

    it "should not allow changes after leaving open state" do
      @invoice.mark_pending!
      @invoice.total = 12.00
      @invoice.save.should be_false
      @invoice.errors.full_messages.should == [I18n.t('invoice.uneditable')]

      @invoice.reload
      @invoice.mark_paid!
      @invoice.description = "asdfsdfasfsdfsdfasfsfds"
      @invoice.save.should be_false

      @invoice.errors.full_messages.should == [I18n.t('invoice.uneditable')]
    end

  end
end
