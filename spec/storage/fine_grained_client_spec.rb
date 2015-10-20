
require 'spec_helper'

describe FineGrainedClient do

  before :each do
    @fgc = FineGrainedClient.new
  end

  context "arrays" do
    it "should allow reading arrays" do
      @fgc.del("an_array")
      @fgc.push("an_array", 'a')
      @fgc.push("an_array", 'bbb')
      @fgc.lread("an_array").should == ["a", 'bbb']
    end

    it "should permit clearing an array" do
      @fgc.lclear("a")
      @fgc.lread("a").should == []

      30.times { |i| @fgc.push("a", i.to_s) }

      @fgc.lread("a").length.should == 30
      @fgc.lclear("a")
      @fgc.lread("a").length.should == 0
    end
  end
end
