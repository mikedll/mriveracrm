
describe User do
  it "should be creatable" do
    @user = FactoryGirl.create(:user)
    @user.valid?.should be_true
  end

  context "scopes" do
    it "should be able to lookup by business" do
      business = FactoryGirl.create(:employment).business
      user = User.by_employment(business).first
      user.should_not be_nil
    end

    it "should be able to lookup by credntial email", :current => true do
      business = FactoryGirl.create(:employment).business
      cred_email = business.employees.first.users.first.credentials.first.email
      user = User.by_employment(business).by_credential_email(cred_email).first
      user.should_not be_nil
      user.email.should == cred_email
    end
  end
end
