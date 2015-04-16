
require 'spec_helper'

describe SEORanker do
  context "live", :uses_search_engine => true do
    context "rank" do
      it "should connect to public servers and come up with a ranking" do
        @seo_ranker = FactoryGirl.create(:seo_ranker)
        @seo_ranker.rank!
        @seo_ranker.ranking.should_not == 0
      end
    end
  end

  context "validations" do

    it "should not allow more than one persistent request at a time" do
      @seo_ranker = FactoryGirl.create(:seo_ranker) do
        @seo_ranker.start_persistent_request('rank!')
        @seo_ranker.rank!.should be_false

        @seo_ranker.stop_persistent_request('rank!')
        @seo_ranker.rank!.should be_true
      end
    end

    it "should enforce validation tiers" do
      @seo_ranker = FactoryGirl.build(:seo_ranker, :search_phrase => "")
      b = @seo_ranker.business

      @seo_ranker.business_id = nil
      @seo_ranker.valid?.should be_false
      @seo_ranker.errors[:search_phrase].should be_empty

      10.times { FactoryGirl.create(:seo_ranker, :business => b) }
      @seo_ranker.business_id = b.id
      @seo_ranker.valid?.should be_false
      @seo_ranker.errors[:search_phrase].should be_empty

      @seo_ranker.business.seo_rankers.destroy_all
      @seo_ranker.valid?.should be_false
      @seo_ranker.errors[:search_phrase].should_not be_empty
    end
  end
end
