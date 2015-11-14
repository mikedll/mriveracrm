
require 'spec_helper'

describe AttributesInFineGrained do

  class InterestingObject
    include AttributesInFineGrained
    counter :resources
    attr_accessor :id

    def initialize(id)
      self.id = id
    end
  end

  context "basics" do
    before :each do
      @obj = InterestingObject.new(1)
      @fgc = FineGrainedClient.cli
    end

    it "should permit storage of attributes of active record objects outside of the active record store and in the fine grained database", :current => true do
      @obj.resources == 0
      @obj.resources.incr
      @obj.resources.should == 1
      @fgc.cread("interesting_object:1:resources").should == 1
      @obj.resources.decr
      @fgc.cread("interesting_object:1:resources").should == 0
      @obj.resources.should == 0
    end
  end
end
