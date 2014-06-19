
require 'spec_helper'

describe Manage::InvoicesController do

  context "typical usage" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      @client = FactoryGirl.create(:client, :business => @user.business)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should allow invoices to be created by employee" do
      @client.invoices.count.should == 0
      post :create, {:format => 'js', :client_id => @client.id, "total" => 10, "description" => "Latest invoice"}
      @client.invoices.count.should == 1
      response.should be_success
      response.status.should == 201
    end
  end

  context "filters" do
    it "should bounce a client if he tries to login to this view" do
      Stripe::Customer.stub(:create) { ApiStubs.stripe_create_customer }

      @user = FactoryGirl.create(:client_user)
      @client = FactoryGirl.create(:client, :business => @user.business)
      sign_in @user
      request.host = @user.client.business.host
      
      get :index, {:format => 'js', :client_id => @client.id}

      response.should redirect_to new_user_session_path
      response.should_not be_success
    end
  end


end
