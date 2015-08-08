
require 'spec_helper'

describe Manage::ClientsController do

  context "security basics" do
    before do
      @mfe = FactoryGirl.create(:marketing_front_end)
      request.host = @mfe.host # "www.test.com" # @mfe.host
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
    end

    context "happy paths" do
      it "should allow access if reached via MFE route" do
        get :index, :business_handle => @user.employee.business.handle
        response.should be_success
      end

      it "should allow access if reached via business host" do
        request.host = @user.employee.business.host
        get :index
        response.should be_success
      end
    end

    it "should redirect if domain isnt www" do
      request.host = "mikedll.com"
      get :index
      response.should redirect_to(:host => 'www.mikedll.com')
    end

    it "should redirect to bhandle url if user is signed in and tried to access plainly with mfe" do
      get :index
      response.should redirect_to(bhandle_manage_clients_path(:business_handle => @user.employee.business.handle))
    end

    it "should not allow a person to access clients from another business that isnt theirs" do
      request.host = FactoryGirl.create(:business).host

      get :index, :format => :html
      response.status.should == 404

      get :index, :format => :json
      response.status.should == 404
    end

    context "business's plan and feature support" do

      render_views

      it "should deny access if business plan is dead" do
        @user.employee.business.usage_subscription.payment_gateway_profile.update_attributes!(:stripe_status => PaymentGatewayProfile::Status::PAST_DUE)
        get :index, :business_handle => @user.employee.business.handle
        flash[:error].should == I18n.t('business.errors.inactive_plan_internal')
        response.should_not be_success
      end

      it "should deny access if business does not support this feature" do
        SpecSupport.without_feature(@user, Feature::Names::CLIENTS)
        get :index, :business_handle => @user.employee.business.handle
        flash[:error].should == I18n.t('business.errors.feature_not_supported')
        response.should_not be_success
      end

      it "should show invoice button with invoicing support" do
        get :index, :business_handle => @user.employee.business.handle
        response.body.should have_css('a.invoices.btn')
      end

      it "should hide invoice button without invoicing support" do
        SpecSupport.without_feature(@user, Feature::Names::INVOICING)
        get :index, :business_handle => @user.employee.business.handle
        response.body.should_not have_css('a.invoices.btn')
      end
    end
  end

  context "routine use" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should be able to create clients" do
      @user.employee.business.clients.count.should == 0
      post :create, {:format => "js"}
      @user.employee.business.clients.count.should == 1
      response.status.should == 201
    end
  end
end
