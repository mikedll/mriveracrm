
require 'spec_helper'

describe PersistentRequestable do

  class Jungle
    include PersistentRequestable
    attr_accessor :id
    def initialize(id)
      self.id = id
      self.persistent_requests_count.reset
      self.persistent_requests.clear
    end

    def new_record?; false; end

    def grow!
      return false if !start_persistent_request('grow!')
      stop_persistent_request('grow!')
      true
    end
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
