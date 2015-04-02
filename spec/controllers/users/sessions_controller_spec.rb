
require 'spec_helper'

describe Users::SessionsController do

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:employee_user)
    request.host = @user.employee.business.host
  end

  it "should redirect to google with proper business oauth key" do
    get :authorize, :provider => :google_oauth2
    @user.employee.business.google_oauth2_client_id
    expected = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=google_oauth2_client_idxxx"
    response.header['Location'].should =~ /#{Regexp.escape(expected)}/
  end

  it "should skip session creation if user is already logged in" do
    sign_in @user
    get :authorize, :provider => :google_oauth2
    expect(response).to redirect_to(manage_clients_path)
  end
end
