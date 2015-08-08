
require 'spec_helper'

describe Notification do
  context "associations" do
    it "should be destroyed with a business", :current => true do
      n = FactoryGirl.create(:notification)
      b = Business.find n.business_id
      b.destroy
      expect { n.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
