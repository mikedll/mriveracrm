
require 'spec_helper'

describe ODeskLister do
  context "live", :uses_search_engine => true do
    context "rank" do
      before do
        @odesk_lister = FactoryGirl.create(:live_odesk_lister)
      end

      it "should connect to public servers and come up with a ranking" do
        @odesk_lister.rank!
        @odesk_lister.ranking.should_not == 0
      end
    end
  end

  context "persistent requests" do
    it "should disable repetitive ranking attempts with PersistentRequestable", :current => true do
      @odesk_lister = FactoryGirl.create(:odesk_lister)

      @odesk_lister.start_persistent_request('rank!').should be_true
      @odesk_lister.available_for_request?.should be_false

      @odesk_lister.start_persistent_request('rank!').should be_false
      @odesk_lister.rank!.should be_false
      @odesk_lister.rank!.should be_false

      @odesk_lister.stop_persistent_request('rank!')
      @odesk_lister.available_for_request?.should be_true
      @odesk_lister.rank!.should be_true

      @odesk_lister.start_persistent_request('rank!')
      @odesk_lister.available_for_request?.should be_false
      @odesk_lister.rank!.should be_false
      @odesk_lister.rank!.should be_false

      @odesk_lister.stop_persistent_request('rank!')
      @odesk_lister.available_for_request?.should be_true
      @odesk_lister.rank!.should be_true
    end
  end

  context "validations" do

    it "should enforce validation tiers" do
      @odesk_lister = FactoryGirl.build(:odesk_lister, :search_phrase => "")
      b = @odesk_lister.business

      @odesk_lister.business_id = nil
      @odesk_lister.valid?.should be_false
      @odesk_lister.errors[:search_phrase].should be_empty

      10.times { FactoryGirl.create(:odesk_lister, :business => b) }
      @odesk_lister.business_id = b.id
      @odesk_lister.valid?.should be_false
      @odesk_lister.errors[:search_phrase].should be_empty

      @odesk_lister.business.odesk_listers.destroy_all
      @odesk_lister.valid?.should be_false
      @odesk_lister.errors[:search_phrase].should_not be_empty
    end
  end
end
