
describe User do
  it "should be creatable" do
    @user = FactoryGirl.create(:user)
    @user.valid?.should be_true
  end

  context "scopes", :current => true do
    it "should be able to lookup by business" do
      business = FactoryGirl.create(:employment).business
      user = User.by_employment(business).first
      user.should_not be_nil
    end
  end
end
