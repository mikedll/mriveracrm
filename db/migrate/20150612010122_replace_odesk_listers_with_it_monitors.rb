class ReplaceOdeskListersWithHTTPMonitors < ActiveRecord::Migration
  def up
    remove_table :odesk_listers, :it_monitors

    remove_column :it_monitors, :search_phrase
    remove_column :it_monitors, :search_engine
    remove_column :it_monitors, :ranking
    remove_column :it_monitors, :matching_url
    remove_column :it_monitors, :matching_title
    remove_column :it_monitors, :runs_since_window_started
    remove_column :it_monitors, :last_window_started_at

    add_column :it_monitors, :target_url,     :default => "", :null => false
  end

  def down
    remove_column :it_monitors, :target_url

    add_column :it_monitors, :last_window_started_at,    :datetime, :null => false
    add_column :it_monitors, :runs_since_window_started, :integer,  :default => 0, :null => false
    add_column :it_monitors, :matching_title, :string,              :default => "",    :null => false
    add_column :it_monitors, :matching_url, :string,                :default => "",    :null => false
    add_column :it_monitors, :ranking, :integer,                    :default => 0,     :null => false
    add_column :it_monitors, :search_engine, :string,               :default => "",    :null => false
    add_column :it_monitors, :search_phrase, :string,               :default => "",    :null => false

    rename_table :it_monitors, :odesk_listers
  end
end
