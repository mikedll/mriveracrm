
require 'spec_helper'

describe PersistentRequestable do

  class Jungle
    extend ActiveModel::Callbacks
    extend ActiveModel::Naming

    define_model_callbacks :destroy

    include PersistentRequestable

    attr_accessor :id
    attr_reader :errors

    def initialize(id)
      self.id = id
      @errors = ActiveModel::Errors.new(self)
    end

    def read_attribute_for_validation(attr)
      send(attr)
    end

    def Jungle.human_attribute_name(attr, options = {})
      attr
    end

    def Jungle.lookup_ancestors
      [self]
    end

    def new_record?; false; end
    def changed?; false; end

    def grow!
      return false if !start_persistent_request('grow!')
      stop_persistent_request('grow!')
      true
    end

    def destroy
      run_callbacks :destroy do
        # noop
      end
    end
  end

  it "should clean redis on destroy" do
    FineGrainedClient.cli.keys.each do |k|
      FineGrainedClient.cli.del(k)
    end

    j = Jungle.new(1)
    FineGrainedClient.cli.keys.should =~ []
    j.grow!
    FineGrainedClient.cli.keys =~ [j.persistent_requests_count.key]
    j.destroy
    FineGrainedClient.cli.keys.should == []
  end

  it "should lock record to one request at a time with redis" do
    j = Jungle.new(2)

    j.start_persistent_request('grow!').should be_true
    j.available_for_request?.should be_false

    j.start_persistent_request('grow!').should be_false
    j.grow!.should be_false
    j.grow!.should be_false

    j.stop_persistent_request('grow!')
    j.available_for_request?.should be_true
    j.grow!.should be_true

    j.start_persistent_request('grow!')
    j.available_for_request?.should be_false
    j.grow!.should be_false
    j.grow!.should be_false

    j.stop_persistent_request('grow!')
    j.available_for_request?.should be_true
    j.grow!.should be_true
  end
end
