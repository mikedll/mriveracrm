
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
end
