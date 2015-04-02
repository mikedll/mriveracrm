require 'spec_helper'

describe Manage::ProductImagesController do
  context "basics" do
    before(:each) do
      @user = FactoryGirl.create(:employee_user)
      sign_in @user
      request.host = @user.employee.business.host
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

    it "should be able to make a product_image primary" do
      @product_image = FactoryGirl.create(:product_image, :product => @product)
      @product_image2 = FactoryGirl.create(:product_image, :product => @product, :primary => true)
      @product_image3 = FactoryGirl.create(:product_image, :product => @product)

      @product_image.primary.should be_false
      @product_image.active.should be_false
      @product_image2.primary.should be_true
      @product_image2.active.should be_true
      @product_image3.primary.should be_false
      put :toggle_primary, {:format => :json, :id => @product_image.id, :product_id => @product_image.product_id }
      @product_image.reload
      @product_image.primary.should be_true
      @product_image.active.should be_true
      @product_image2.reload.primary.should be_false
    end
  end
end
