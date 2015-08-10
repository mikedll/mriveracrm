
require 'spec_helper'

describe PersistentRequestable do

  class Jungle
    extend ActiveModel::Callbacks

    define_model_callbacks :destroy

    include PersistentRequestable

    attr_accessor :id
    def initialize(id)
      self.id = id
    end

    def new_record?; false; end

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
    j = Jungle.new(1)
    Redis.current.keys("*").should =~ []
    j.grow!
    Redis.current.keys("*").should =~ [j.persistent_requests_count.key]
    j.destroy
    Redis.current.keys("*").should == []
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
