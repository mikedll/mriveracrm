
require 'spec_helper'

describe Page do
  context "rendering", :current => true do
    before :each do
      @page = FactoryGirl.create(:page)
    end

    it "should convert markdown as needed" do

    end
  end
end
