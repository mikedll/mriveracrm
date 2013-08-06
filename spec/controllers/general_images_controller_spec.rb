require 'spec_helper'

describe Manage::GeneralImagesController do
  context "basics" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.domain
      @product = FactoryGirl.create(:product)
    end

    it "should receive attachment" do
      file = File.new(Rails.root.join('spec', 'support', 'testphoto.jpg'), 'r')
      file.size.should be > 0
      post :create, {:format => "js", :data => file}

      puts response.body.to_yaml

      GeneralImages.count.should == 1      
    end
  end
end
