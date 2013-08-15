
require 'spec_helper'

describe Product do

  context "relationships" do
    before(:each) do
      @product = FactoryGirl.create(:product)
    end

    it "should relate to many images" do

      # sort of a demo of rails more than a real spec of our app.
      # thats okay.

      image = FactoryGirl.create(:image)
      image2 = FactoryGirl.create(:image)
      @product.images.push(image2)
      
      product2 = FactoryGirl.create(:product)
      product2.images.push(image2)
      product2.images.push(image)

      res = Image.connection.execute "select * from product_images"
      res.count.should == 3
      res.first.tap do |r|
        r['image_id'].to_i.should == image2.id
        r['product_id'].to_i.should == @product.id
      end

      reloaded_image2 = Image.find image2.id
      p = reloaded_image2.products.first
      reloaded_image2.products.delete(p)

      res = Image.connection.execute "select * from product_images"
      res.count.should == 2
      Image.count.should == 2
      Product.count.should == 2
    end
  end

  context "search" do
    it "should search in product's name", :current => true do
      Product.create(:name => "Cat Food")
      Product.create(:name => "Dog Food")
      Product.create(:name => "Forks")
      Product.create(:name => "Luxury Knives")
      
      p = Product.search("knive")
      p.count.should == 1
    end
  end
end
