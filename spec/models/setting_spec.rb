require 'spec_helper'

describe Setting do

  context "validations" do
    it "should cast to type for bool" do
      @setting = FactoryGirl.create(:setting, :value_type => "Boolean", :value => true)
      @setting.get.should == true
    end
  end
end
