
require 'spec_helper'

describe Image do
  context "uploader" do
    before do
      @uuid = '686796a4-7a4f-4c22-b462-5ee9b99c6f91'
      @testfilepath = Rails.root.join('spec', 'support', 'testphoto.jpg')
      SecureRandom.stub(:uuid) { @uuid }
      @image = FactoryGirl.create(:image, :data => File.new(@testfilepath, 'r'))
    end

    it "should create UUIDs to use in urls, to hide image name" do
      @image.data.url.should =~ Regexp.new("#{@uuid}.jpg$")
      @image.data.url.should_not =~ /testphoto.jpg/
    end

    it "should re-get a new UUID if content changes. other versions should NOT change uuid" do
      CarrierWave.configure { |c| c.enable_processing = true }

      @image.data.versions.count.should == 4
      @image.data.url.should =~ Regexp.new("#{@uuid}.jpg$")

      @uuid2 = '686796a4-7a4f-4c22-b462-5ee9b99c6f92'
      SecureRandom.unstub(:uuid)
      SecureRandom.stub(:uuid) { @uuid2 }

      @image.data = File.new(Rails.root.join('spec', 'support', 'testphoto2.jpg'), 'r')
      @image.save

      @image.data.url.should =~ Regexp.new("#{@uuid2}.jpg$")
      CarrierWave.configure { |c| c.enable_processing = false }
    end

    it "should remember original filename despite using uuids"  do      
      @image.data_original_filename.should == "testphoto.jpg"
    end
  end
end
