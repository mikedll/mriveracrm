
require 'spec_helper'

describe Manage::MonitoredComputersController do

  context "creation", :current => true do
    before :each do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should allow create" do
      @user.business.it_monitored_computers.count.should == 0
      post :create, { :monitored_computer => { 'name' => "Special Client" } }
      @user.business.it_monitored_computers.count.should == 1
    end
  end

end
