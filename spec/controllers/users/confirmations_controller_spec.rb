
require 'spec_helper'
describe Users::ConfirmationsController do
  context "post confirmation redirect" do
    it "should redirect to mfe with handle", :current => true do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = FactoryGirl.create(:unconfirmed_new_employee_user)
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts "#{@user}"

      get :show, :confirmation_token => @user.confirmation_token
      expect(response).to redirect_to(manage_clients_path)
    end
  end
end

