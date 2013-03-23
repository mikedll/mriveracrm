
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
      business = FactoryGirl.create(:employment).business
      user = User.by_employment(business).first
      user.should_not be_nil
    end

    it "should be able to lookup by credntial email" do
      employment = FactoryGirl.create(:employment)
      business = employment.business
      cred_email = business.employees.first.users.first.credentials.first.email
      user = User.by_employment(business).by_credential_email(cred_email).first
      user.should_not be_nil
      user.email.should == cred_email
    end
  end
end
