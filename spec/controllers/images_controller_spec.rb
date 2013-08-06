require 'spec_helper'

describe Manage::ImagesController do
  context "basics" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.domain
      @product = FactoryGirl.create(:product, :business => @user.business)
    end

    it "should receive attachment" do
      file = File.new(Rails.root.join('spec', 'support', 'testphoto.jpg'), 'r')
      file.size.should be > 0

      @product.images.count.should == 0
      post :create, {:format => "json", :product_id => @product.id, :data => file}
      @product.images.count.should == 1

      Image.count.should == 1      
    end
  end
end
