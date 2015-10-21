
require 'spec_helper'

describe FineGrainedClient do

  before :each do
    @fgc = FineGrainedClient.new
  end

  context "live", :live_fine_grained => true do
    context "lists" do
      it "should allow retrieving an list's size" do
        @fgc.del("an_list")
        @fgc.push("an_list", 'a')
        @fgc.push("an_list", 'bbb')
        @fgc.llength("an_list").should == 2
      end

      it "should allow reading lists" do
        @fgc.del("an_list")
        @fgc.push("an_list", 'a')
        @fgc.push("an_list", 'bbb')
        @fgc.push("an_list", 'ccc')
        @fgc.push("an_list", '454')
        @fgc.lread("an_list").should == ["a", 'bbb', 'ccc', '454']
        @fgc.lread("an_list", 0, 2).should == ["a", 'bbb']
        @fgc.lread("an_list", 2, 2).should == ['ccc', '454']
        @fgc.lread("an_list", 2, 20).should == ['ccc', '454']
      end

      it "should permit clearing an list" do
        @fgc.lclear("a")
        @fgc.lread("a").should == []

        30.times { |i| @fgc.push("a", i.to_s) }

        @fgc.lread("a").length.should == 30
        @fgc.lclear("a")
        @fgc.lread("a").length.should == 0
      end
    end
  end

end
