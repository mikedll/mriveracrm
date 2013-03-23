
require 'spec_helper'

describe User do
  it "should be creatable" do
    @user = FactoryGirl.create(:user)
    @user.valid?.should be_true
  end

  context "find_for_google_oauth2" do
    it "should succeed with proper auth hash and no current user" do
      cred = FactoryGirl.build(:credential)
      FactoryGirl.create(:employee_invitation, :email => cred.email)
      user = User.find_for_google_oauth2({
                                           :uid => cred.uid,
                                           :info => {
                                             :email => cred.email,
                                             :name => cred.name,
                                             :first_name => 'Bob',
                                             :last_name => 'Jenkins'
                                           },
                                           :credentials => {
                                             :token => cred.oauth2_access_token,
                                             :expires_at => cred.oauth2_access_token_expires_at.to_i,
                                             :refresh_token => cred.oauth2_refresh_token
                                           }
                                         }, nil)
      user.persisted?.should be_true
    end
  end

  context "scopes" do
    it "should be able to lookup by business" do
      FactoryGirl.create(:client_user)
      user = User.cb.first
      user.should_not be_nil
    end

    it "should be able to lookup by google_oauth2" do
      user = FactoryGirl.create(:employee_user)
      business = user.business
      business.reload
      user = User.cb.google_oauth2(business.employees.first.user.credentials.first.email).first
      user.should_not be_nil
      user.email.should == business.employees.first.user.credentials.first.email
    end
  end
end
