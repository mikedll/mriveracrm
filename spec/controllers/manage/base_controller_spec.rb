
require 'spec_helper'

describe Manage::BaseController do

  before :each do
    @user = FactoryGirl.create(:employee_user)
    sign_in @user
    request.host = @user.employee.business.host
  end

  render_views

  context "business menus" do

    controller(Manage::BaseController) do
      skip_before_filter :_require_business_support
      def index
        render "home/index", :layout => "application"
      end
    end

    it "should show supported features" do
      get :index
      response.should be_success
      response.body.should have_css("a[href=\"#{manage_products_path}\"]")
      response.body.should have_css("a[href=\"#{manage_clients_path}\"]")
    end

    it "should hide unsupported features" do
      SpecSupport.without_feature(@user, Feature::Names::PRODUCTS)
      SpecSupport.without_feature(@user, Feature::Names::CLIENTS)
      get :index
      response.should be_success
      response.body.should_not have_css("a[href=\"#{manage_clients_path}\"]")
      response.body.should_not have_css("a[href=\"#{manage_products_path}\"]")
    end

    it "should show business menus if an owner" do
      sign_in @user.employee.business.an_owner
      get :index
      response.should be_success
      response.body.should have_css("a[href=\"#{manage_business_path}\"]")
      response.body.should have_css("a[href=\"#{manage_billing_settings_path}\"]")
      response.body.should have_css("a[href=\"#{manage_status_monitor_path}\"]")
    end

    it "should hide business menus if not an owner" do
      get :index
      response.should be_success
      response.body.should_not have_css("a[href=\"#{manage_business_path}\"]")
      response.body.should_not have_css("a[href=\"#{manage_billing_settings_path}\"]")
      response.body.should_not have_css("a[href=\"#{manage_status_monitor_path}\"]")
    end

    it "should show admin menu if admin present" do
      @user.is_admin = true
      @user.save!
      get :index
      response.body.should have_css("a[href=\"#{abdiel_root_path}\"]")
    end

    it "should hide admin menu if not admin" do
      get :index
      response.body.should_not have_css("a[href=\"#{abdiel_root_path}\"]")
    end
  end

  context "business menus with inactive plan" do

    controller(Manage::BaseController) do
      skip_before_filter :require_active_plan
      skip_before_filter :_require_business_support
      def index
        render "home/index", :layout => "application"
      end
    end

    it "should show business menus if business owner even if plan is inactive" do
      @user.employee.business.usage_subscription.payment_gateway_profile.update_attributes!(:stripe_status => PaymentGatewayProfile::Status::PAST_DUE)
      sign_in @user.employee.business.an_owner
      get :index
      response.should be_success
      response.body.should have_css("a[href=\"#{manage_business_path}\"]")
      response.body.should have_css("a[href=\"#{manage_billing_settings_path}\"]")
      response.body.should have_css("a[href=\"#{manage_status_monitor_path}\"]")
    end
  end

end
