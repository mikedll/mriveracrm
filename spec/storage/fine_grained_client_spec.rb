
require 'spec_helper'

describe FineGrainedClient do

  before :each do
    @fgc = FineGrainedClient.new
  end

  context "live", :live_fine_grained => true do

    context "sets" do
      it "should store elements without permitting duplication" do
        @fgc.del("account:5:requests")
        @fgc.sadd("account:5:requests", "stripe_request")
        @fgc.sadd("account:5:requests", "stripe_request")
        @fgc.sadd("account:5:requests", "stripe_request2")
        @fgc.slength("account:5:requests").should == 2
        @fgc.smember("account:5:requests", "stripe_request").should be_true
        @fgc.sread("account:5:requests").should =~ ["stripe_request", "stripe_request2"]
        @fgc.srem("account:5:requests", "stripe_request")
        @fgc.srem("account:5:requests", "stripe_request2")
        @fgc.sread("account:5:requests").should == []
      end
    end
    context "counters" do
      it "should be incrementable and decrementable" do
        @fgc.del("account:5:ready")
        @fgc.incr("account:5:ready").should == 1
        @fgc.cread("account:5:ready").should == 1
        @fgc.incr("account:5:ready").should == 2
        @fgc.decr("account:5:ready").should == 1
        @fgc.decr("account:5:ready").should == 0
      end
    end

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

    context "shift" do
      it "should queue for five seconds before failing" do

        t1 = Thread.new do
          sleep 3 # make t2 and t3 wait for 3 and 2 seconds, respectively
          fgc = FineGrainedClient.new
          fgc.push("q2", "a job")
          fgc.push("q2", "another job")
        end

        t2 = Thread.new do
          fgc = FineGrainedClient.new
          r = fgc.shift("q2")
          r.should == "a job"
        end

        t3 = Thread.new do
          sleep 1 # go after t2
          fgc = FineGrainedClient.new
          r = fgc.shift("q2")
          r.should == "another job"
        end

        t4 = Thread.new do
          sleep 3 # go after t2 and t3
          fgc = FineGrainedClient.new
          r = fgc.shift("q2")
          r.should be_nil
        end

        t1.join
        t2.join
        t3.join
        t4.join

      end
    end
  end

end
