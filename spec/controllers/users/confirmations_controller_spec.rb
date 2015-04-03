
require 'spec_helper'

describe Users::ConfirmationsController do
  context "post confirmation redirect" do
    it "should redirect to mfe with handle" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @mfe = FactoryGirl.create(:marketing_front_end)
      request.host = @mfe.host

      @user = FactoryGirl.create(:unconfirmed_new_employee_user)
      get :show, :confirmation_token => @user.confirmation_token

      expect(response).to redirect_to(bhandle_manage_clients_path(:business_handle => @user.employee.business.handle))
    end
  end
end

