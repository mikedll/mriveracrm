
require 'spec_helper'

describe Users::ConfirmationsController do
  context "post confirmation redirect" do
    it "should redirect to mfe with handle", :current => true do
      @mfe = FactoryGirl.create(:marketing_front_end)
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.create(:unconfirmed_new_employee_user)
      request.host = @mfe.host
      get :show, :confirmation_token => @user.confirmation_token
      expect(response).to redirect_to(bhandle_manage_clients_path(:business_handle => @user.employee.business.handle))
    end
  end
end

