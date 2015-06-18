class RemoveGoogleAnalytics < ActiveRecord::Migration
  def up
    remove_column :businesses, :google_analytics_id
  end

  def down
    add_column :businesses, :google_analytics_id, :string, :null => false, :default => ""
  end
end
