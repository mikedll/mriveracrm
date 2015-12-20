class RenameSeoRankersToOdeskListers < ActiveRecord::Migration
  def up
    rename_table :seo_rankers, :odesk_listers
  end

  def down
    rename_table :odesk_listers, :seo_rankers
  end
end
