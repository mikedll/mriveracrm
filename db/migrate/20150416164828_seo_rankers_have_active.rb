class SeoRankersHaveActive < ActiveRecord::Migration
  def up
    add_column :seo_rankers, :active, :boolean, :null => false, :default => false
  end

  def down
    remove_column :seo_rankers, :active
  end
end
