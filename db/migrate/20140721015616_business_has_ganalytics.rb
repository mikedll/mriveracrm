class BusinessHasGanalytics < ActiveRecord::Migration
  def up
    add_column :businesses, :google_analytics_id, :string, :null => false, :default => ""
  end

  def down
    remove_column :businesses, :google_analytics_id
  end
end
