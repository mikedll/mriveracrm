class ReplaceOdeskListersWithITMonitoredComputers < ActiveRecord::Migration
  def up
    rename_table :odesk_listers, :it_monitored_computers

    remove_column :it_monitored_computers, :search_phrase
    remove_column :it_monitored_computers, :search_engine
    remove_column :it_monitored_computers, :ranking
    remove_column :it_monitored_computers, :matching_url
    remove_column :it_monitored_computers, :matching_title
    remove_column :it_monitored_computers, :runs_since_window_started
    remove_column :it_monitored_computers, :last_window_started_at

    rename_column :it_monitored_computers, :last_polled_at, :last_heartbeat_received_at

    add_column :it_monitored_computers, :hostname, :string, :default => "", :null => false

    add_column :it_monitored_computers, :last_result, :integer
    add_column :it_monitored_computers, :missing, :boolean, :null => false, :default => false
  end

  def down
    remove_column :it_monitored_computers, :missing
    remove_column :it_monitored_computers, :last_result
    remove_column :it_monitored_computers, :port
    remove_column :it_monitored_computers, :hostname

    add_column :it_monitored_computers, :last_window_started_at,    :datetime
    execute "UPDATE it_monitored_computers SET last_window_started_at = now()"
    change_column :it_monitored_computers, :last_window_started_at, :datetime, :null => false

    rename_column :it_monitored_computers, :last_heartbeat_received_at, :last_polled_at

    add_column :it_monitored_computers, :runs_since_window_started, :integer,  :default => 0, :null => false
    add_column :it_monitored_computers, :matching_title, :string,              :default => "",    :null => false
    add_column :it_monitored_computers, :matching_url, :string,                :default => "",    :null => false
    add_column :it_monitored_computers, :ranking, :integer,                    :default => 0,     :null => false
    add_column :it_monitored_computers, :search_engine, :string,               :default => "",    :null => false
    add_column :it_monitored_computers, :search_phrase, :string,               :default => "",    :null => false

    rename_table :it_monitored_computers, :odesk_listers
  end
end
