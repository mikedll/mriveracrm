require 'spec_helper'

describe BusinessesController do

  render_views

  context "security" do
    before :each do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
    end

    context "menu" do
      it "should show products when supported" do
        get :show
        response.body.should match Regexp.escape(products_path)
      end

      it "should not show products in menu if there is no feature support" do
        SpecSupport.without_feature(@user, Feature::Names::PRODUCTS)
        get :show
        response.body.should_not match Regexp.escape(products_path)
      end

      it "should respect ordering of CMS entries" do
        get :show

        assert_select ".nav.nav-tabs" do
          links = css_select("a")
          links[1].to_s.should match Regexp.escape(products_path)
          links[2].to_s.should match Regexp.escape(contact_home_path)
        end
      end
    end
  end
end
