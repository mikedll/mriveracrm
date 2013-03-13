
describe User do
  it "should be creatable" do
    @user = FactoryGirl.create(:user)
    @user.valid?.should be_true
  end
end
