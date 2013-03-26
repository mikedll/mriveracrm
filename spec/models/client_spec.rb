
require 'spec_helper'

describe Client do
  context "validations" do
    it "should validation email" do
      client = FactoryGirl.create(:stubbed_client)
      client.email = "asdf"
      client.save.should be_false
      client.email = ""
      client.save.should be_false
    end
  end
end
