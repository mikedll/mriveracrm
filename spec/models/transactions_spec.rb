
require 'spec_helper'

describe Transaction do
  context "destroy" do
    it "should not be destroyable unless its an outside transaction" do
      t = FactoryGirl.create(:stripe_transaction)
      t.destroy.should be_false

      t = FactoryGirl.create(:authorize_net_transaction)
      t.destroy.should be_false

      t = FactoryGirl.create(:outside_transaction)
      t.destroy.should be_true
    end
  end

  context "defaults" do
    it "should use invoice total if no amount is given" do
      i = FactoryGirl.create(:invoice)
      ot = i.outside_transactions.build
      ot.save!

      ot.amount.should == i.total
      ot.amount.should_not == 0.0

      i = FactoryGirl.create(:invoice)
      ot = i.outside_transactions.build
      ot.amount = 2.33
      ot.save!

      ot.amount.should == 2.33      
    end
  end

  context "editing" do
    it "should not be editable if its a stripe transaction" do
      t = FactoryGirl.create(:stripe_transaction, :status => :open)
      t.amount = t.amount + 5.0
      t.save.should be_false
    end

    it "should not be editable if its pending" do
      t = FactoryGirl.create(:outside_transaction, :status => "open")
      t.amount = t.amount + 5.0
      t.save.should be_true

      t.begin!

      t.amount = t.amount + 5.0
      t.save.should be_false      
    end
  end

end
