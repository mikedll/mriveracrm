
require 'spec_helper'

describe It::Monitor do

  context "live", :uses_search_engine => true do
    context "rank" do
      before do
        @monitor = FactoryGirl.create(:live_http_monitor)
      end

      it "should connect to public servers and come up with a ranking" do
        @monitor.rank!
        @monitor.ranking.should_not == 0
      end
    end
  end

  context "persistent requests" do
    it "should disable repetitive ranking attempts with PersistentRequestable", :current => true do
      @monitor = FactoryGirl.create(:http_monitor)

      @monitor.start_persistent_request('rank!').should be_true
      @monitor.available_for_request?.should be_false

      @monitor.start_persistent_request('rank!').should be_false
      @monitor.rank!.should be_false
      @monitor.rank!.should be_false

      @monitor.stop_persistent_request('rank!')
      @monitor.available_for_request?.should be_true
      @monitor.rank!.should be_true

      @monitor.start_persistent_request('rank!')
      @monitor.available_for_request?.should be_false
      @monitor.rank!.should be_false
      @monitor.rank!.should be_false

      @monitor.stop_persistent_request('rank!')
      @monitor.available_for_request?.should be_true
      @monitor.rank!.should be_true
    end
  end

  context "validations" do

    it "should enforce validation tiers" do
      @monitor = FactoryGirl.build(:http_monitor, :search_phrase => "")
      b = @monitor.business

      @monitor.business_id = nil
      @monitor.search_phrase = ""
      @monitor.valid?.should be_false
      @monitor.errors[:search_phrase].should be_empty

      @monitor.business_id = b.id
      @monitor.valid?.should be_false
      @monitor.errors[:search_phrase].should_not be_empty
    end
  end
end
