
require 'spec_helper'

describe ProductImage do
  context "primary" do
    it "should imply active, and be true for at most one of a product's images" do
      @product = FactoryGirl.create(:product)
      @product_image = FactoryGirl.create(:product_image, :product => @product, :primary => true)
      @product_image2 = FactoryGirl.create(:product_image, :product => @product, :primary => true)
      @product_image3 = FactoryGirl.create(:product_image, :product => @product, :primary => true)

      @product_image.reload
      @product_image2.reload
      @product_image3.reload

      @product_image.primary.should be_false
      @product_image2.primary.should be_false
      @product_image3.primary.should be_true

      @product_image.update_attributes(:primary => true).should be_true

      @product_image3.reload
      @product_image.active.should be_true
      @product_image.primary.should be_true
      @product_image3.primary.should be_false
    end
  end

end

