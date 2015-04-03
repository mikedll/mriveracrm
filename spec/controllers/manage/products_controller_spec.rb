
require 'spec_helper'

describe Manage::ProductsController do
  context "security" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    it "should deny access without products support" do
      SpecSupport.without_feature(@user, Feature::Names::PRODUCTS)
      get :index
      response.should_not be_success
      flash[:error].should == I18n.t('business.errors.feature_not_supported')
    end
  end
end
