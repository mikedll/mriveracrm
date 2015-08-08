
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
      post :create, { :format => :json, 'name' => "Special Client", 'hostname' => 'crmdev.michaelriveraco.com' }
      @user.business.it_monitored_computers.count.should == 1
      mc = @user.business.it_monitored_computers.first
      mc.hostname.should == 'crmdev.michaelriveraco.com'
    end
  end

end
