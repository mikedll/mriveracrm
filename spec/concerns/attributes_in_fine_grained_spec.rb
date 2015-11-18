
require 'spec_helper'

describe AttributesInFineGrained do

  class InterestingObject
    include AttributesInFineGrained
    counter :resources
    set :resource_uses
    value :last_resource_use_error

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

    it "should permit storage of attributes of active record objects outside of the active record store and in the fine grained database" do
      @obj.resources == 0
      @obj.resources.incr
      @obj.resources.should == 1
      @fgc.cread("interesting_object:1:resources").should == 1
      @obj.resources.decr
      @fgc.cread("interesting_object:1:resources").should == 0
      @obj.resources.should == 0
    end

    it "should permit storage of values of a given record" do
      @obj.last_resource_use_error.should == ""
      @obj.last_resource_use_error = "Something."
      @obj.last_resource_use_error.should == "Something."
      @obj.last_resource_use_error = ""
      @obj.last_resource_use_error.should == ""
    end

    it "should permit set memory" do
      @obj.resource_uses.add("dusting")
      @obj.resource_uses.add("sweeping")
      @obj.resource_uses.include?("dusting").should be_true
      @obj.resource_uses.include?("sweeping").should be_true
      @obj.resource_uses.include?("skiing").should be_false
      @obj.resource_uses.reset
      @obj.resource_uses.include?("dusting").should be_false
      @obj.resource_uses.include?("sweeping").should be_false
    end
  end
end
