
require 'spec_helper'

describe Product do

  context "relationships" do
    before(:each) do
      @product = FactoryGirl.create(:product)
    end

    it "should relate to many images" do

      # sort of a demo of rails more than a real spec of our app.
      # thats okay.

      image = FactoryGirl.create(:general_image)
      image2 = FactoryGirl.create(:general_image)
      @product.general_images.push(image2)
      
      product2 = FactoryGirl.create(:product)
      product2.general_images.push(image2)
      product2.general_images.push(image)

      res = GeneralImage.connection.execute "select * from general_images_products"
      res.count.should == 3
      res.first.tap do |r|
        r['general_image_id'].to_i.should == image2.id
        r['product_id'].to_i.should == @product.id
      end

      reloaded_image2 = GeneralImage.find image2.id
      p = reloaded_image2.products.first
      reloaded_image2.products.delete(p)

      res = GeneralImage.connection.execute "select * from general_images_products"
      res.count.should == 2
      GeneralImage.count.should == 2
      Product.count.should == 2
    end
  end
end
