require 'spec_helper'

describe Manage::StatusMonitorController do

  context "authorization" do
    before :each do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should grant access to business owner" do
      sign_in @user.employee.business.an_owner
      get :show
      response.should be_success
    end

    it "should deny access to non-owning employee user" do
      get :show
      response.should redirect_to business_path
      response.should_not be_success
      flash[:error].should == I18n.t('unauthorized.read.business', :action => "read")
    end

    it "should allow access to business owner even if plan is inactive" do
      @user.employee.business.usage_subscription.payment_gateway_profile.update_attributes!(:stripe_status => PaymentGatewayProfile::Status::PAST_DUE)
      sign_in @user.employee.business.an_owner
      get :show
      response.should be_success
    end

  end

end
