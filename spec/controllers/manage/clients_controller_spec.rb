
require 'spec_helper'

describe Manage::ClientsController do

  context "security basics" do
    before do
      @mfe = FactoryGirl.create(:marketing_front_end)
      request.host = @mfe.host # "www.test.com" # @mfe.host
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
    end

    it "should redirect if domain isnt www" do
      request.host = "mikedll.com"
      get :index
      response.should redirect_to(:host => 'www.mikedll.com')
    end

    it "should redirect to behandle url if user is signed in and tried to access plainly with mfe" do
      get :index
      response.should redirect_to(bhandle_manage_clients_path(:business_handle => @user.employee.business.handle))
    end

    it "should not allow a person to access clients from another business that isnt theirs" do
      request.host = FactoryGirl.create(:business).host

      get :index, :format => :html
      response.status.should == 404

      get :index, :format => :js
      response.status.should == 404
    end

  end

  context "routine use" do
    before(:each) do
      Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer }
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should create clients" do
      @user.employee.business.clients.count.should == 0
      post :create, {:format => "js"}
      @user.employee.business.clients.count.should == 1
      response.status.should == 201
    end
  end
end
