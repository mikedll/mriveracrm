
require 'spec_helper'

describe FineGrainedClient do

  before :each do
    @fgc = FineGrainedClient.new
  end

  context "arrays" do
    it "should allow reading arrays", :current => true do
      @fgc.del("an_array")
      @fgc.push("an_array", 'a')
      @fgc.push("an_array", 'bbb')
      @fgc.lread("an_array").should == ["a", 'bbb']
    end
  end
end
