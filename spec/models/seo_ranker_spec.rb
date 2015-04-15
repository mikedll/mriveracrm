
require 'spec_helper'

describe SEORanker do
  context "live", :uses_search_engine => true do
    context "rank" do
      it "should connect to public servers and come up with a ranking", :current => true do
        @seo_ranker = FactoryGirl.create(:seo_ranker)
        @seo_ranker.rank!
        @seo_ranker.ranking.should_not == 0
      end
    end
  end
end
