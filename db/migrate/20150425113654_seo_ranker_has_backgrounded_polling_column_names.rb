class SEORankerHasBackgroundedPollingColumnNames < ActiveRecord::Migration
  def up
    rename_column :seo_rankers, :last_ranked_at, :last_polled_at
  end

  def down
    rename_column :seo_rankers, :last_polled_at, :last_ranked_at
  end
end
