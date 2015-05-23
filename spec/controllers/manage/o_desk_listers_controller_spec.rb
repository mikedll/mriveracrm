

require 'spec_helper'

describe Manage::ODeskListersController do

  context "creation" do
    before :each do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should allow create" do
      @user.business.odesk_listers.count.should == 0
      post :create, { :odesk_lister => { 'search_phrase' => "rails" } }
      @user.business.odesk_listers.count.should == 1
    end
  end

end
