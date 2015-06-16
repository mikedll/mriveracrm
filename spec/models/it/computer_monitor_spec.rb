
require 'spec_helper'

describe IT::ComputerMonitor do

  context "live", :generic_web_test => true do
    context "poll" do
      it "should connect to public servers and come up with a ranking" do
        @cm = FactoryGirl.create(:live_it_computer_monitor)
        @cm.poll!.should be_true
        @cm.reload
        @cm.last_error.should == ""
        @cm.last_result.should == 200
      end

      it "should count errors and halt after three" do
        @cm = FactoryGirl.create(:live_it_computer_monitor_of_down_site)
        @cm.poll!.should be_true
        @cm.reload
        @cm.last_error.should == "Connection refused - connect(2)"
        @cm.consecutive_error_count.should == 1

        @cm.poll!.should be_true
        @cm.reload
        @cm.consecutive_error_count.should == 2

        @cm.active.should be_true
        @cm.poll!.should be_true
        @cm.reload
        @cm.consecutive_error_count.should == 3
        @cm.active.should be_false
      end
    end
  end

  context "persistent requests" do
    it "should disable repetitive ranking attempts with PersistentRequestable", :current => true do
      @cm = FactoryGirl.create(:it_computer_monitor)

      @cm.start_persistent_request('rank!').should be_true
      @cm.available_for_request?.should be_false

      @cm.start_persistent_request('rank!').should be_false
      @cm.rank!.should be_false
      @cm.rank!.should be_false

      @cm.stop_persistent_request('rank!')
      @cm.available_for_request?.should be_true
      @cm.rank!.should be_true

      @cm.start_persistent_request('rank!')
      @cm.available_for_request?.should be_false
      @cm.rank!.should be_false
      @cm.rank!.should be_false

      @cm.stop_persistent_request('rank!')
      @cm.available_for_request?.should be_true
      @cm.rank!.should be_true
    end
  end

  context "validations" do
    it "should enforce validation tiers" do
      @cm = FactoryGirl.build(:it_computer_monitor, :search_phrase => "")
      b = @cm.business

      @cm.business_id = nil
      @cm.search_phrase = ""
      @cm.valid?.should be_false
      @cm.errors[:search_phrase].should be_empty

      @cm.business_id = b.id
      @cm.valid?.should be_false
      @cm.errors[:search_phrase].should_not be_empty
    end
  end
end
