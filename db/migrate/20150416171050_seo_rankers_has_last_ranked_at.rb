class SeoRankersHasLastRankedAt < ActiveRecord::Migration
  def up
    add_column :seo_rankers, :last_ranked_at, :datetime
  end

  def down
    remove_column :seo_rankers, :last_ranked_at
  end
end
