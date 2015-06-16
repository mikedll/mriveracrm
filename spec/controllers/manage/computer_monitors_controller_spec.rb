
require 'spec_helper'

describe Manage::IT::ComputerMonitorsController do

  context "creation" do
    before :each do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should allow create" do
      @user.business.it_computer_monitors.count.should == 0
      post :create, { :computer_monitor => { 'name' => "my searcher" } }
      @user.business.it_computer_monitors.count.should == 1
    end
  end

end
