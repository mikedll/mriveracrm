
require 'spec_helper'

describe Invoice do

  it "should error out on charge! if invoice is open or paid", :current => true do

    invoice = FactoryGirl.create(:invoice)
    invoice.charge!
    invoice.errors.full_messages.should == [I18n.t('invoice.cannot_pay')]
  end
end
