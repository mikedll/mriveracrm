
require 'spec_helper'

describe IT::MonitoredComputer do

  context "live", :generic_web_test => true, :ignore => true do
    context "poll" do
      it "should connect to public servers and come up with a ranking" do
        @mc = FactoryGirl.create(:live_it_monitored_computer)
        @mc.poll!.should be_true
        @mc.reload
        @mc.last_error.should == ""
        @mc.last_result.should == 200
      end

      it "should count errors and halt after three" do
        @mc = FactoryGirl.create(:live_it_monitored_computer_of_down_site)
        @mc.poll!.should be_true
        @mc.reload
        @mc.last_error.should == "Connection refused - connect(2)"
        @mc.consecutive_error_count.should == 1

        @mc.poll!.should be_true
        @mc.reload
        @mc.consecutive_error_count.should == 2

        @mc.active.should be_true
        @mc.poll!.should be_true
        @mc.reload
        @mc.consecutive_error_count.should == 3
        @mc.active.should be_false
      end
    end
  end

  context "validations" do
    it "should enforce validation tiers", :broken => true do
      @mc = FactoryGirl.build(:it_monitored_computer, :search_phrase => "")
      b = @mc.business

      @mc.business_id = nil
      @mc.search_phrase = ""
      @mc.valid?.should be_false
      @mc.errors[:search_phrase].should be_empty

      @mc.business_id = b.id
      @mc.valid?.should be_false
      @mc.errors[:search_phrase].should_not be_empty
    end
  end
end
