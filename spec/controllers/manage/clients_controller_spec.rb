
require 'spec_helper'

describe Manage::ClientsController do

  context "basics" do
    it "should redirect if domain isnt www" do
      request.host = "mikedll.com"
      get :index
      response.should redirect_to(:host => 'www.mikedll.com')
    end

    it "should asdf" do
      @mfe = FactoryGirl.create(:marketing_front_end)
      @user = FactoryGirl.create(:employee_user)
      sign_in @user

      request.host = @mfe.host # "www.test.com" # @mfe.host
      # request.host = @user.employee.business.host

      get :index
      response.should redirect_to(bhandle_manage_clients_path(:business_handle => @user.employee.business.handle))
    end

  end

  context "routine use", :current => true do
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
