
describe User do
  it "should be creatable" do
    @user = FactoryGirl.create(:user)
    @user.valid?.should be_true
  end

  context "scopes", :current => true do
    it "should be able to lookup by business" do
      business = factory :business
      user = User.by_business(business).first
    end
  end
end
