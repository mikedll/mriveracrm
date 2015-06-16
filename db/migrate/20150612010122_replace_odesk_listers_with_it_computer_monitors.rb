class ReplaceOdeskListersWithITComputerMonitors < ActiveRecord::Migration
  def up
    rename_table :odesk_listers, :it_computer_monitors

    remove_column :it_computer_monitors, :search_phrase
    remove_column :it_computer_monitors, :search_engine
    remove_column :it_computer_monitors, :ranking
    remove_column :it_computer_monitors, :matching_url
    remove_column :it_computer_monitors, :matching_title
    remove_column :it_computer_monitors, :runs_since_window_started
    remove_column :it_computer_monitors, :last_window_started_at

    add_column :it_computer_monitors, :hostname, :string, :default => "", :null => false
    add_column :it_computer_monitors, :port, :integer,    :null => false
    add_column :it_computer_monitors, :last_result, :integer
    add_column :it_computer_monitors, :consecutive_error_count, :integer, :null => false, :default => 0
  end

  def down
    remove_column :it_computer_monitors, :consecutive_error_count
    remove_column :it_computer_monitors, :last_result
    remove_column :it_computer_monitors, :port
    remove_column :it_computer_monitors, :hostname

    add_column :it_computer_monitors, :last_window_started_at,    :datetime, :null => false
    add_column :it_computer_monitors, :runs_since_window_started, :integer,  :default => 0, :null => false
    add_column :it_computer_monitors, :matching_title, :string,              :default => "",    :null => false
    add_column :it_computer_monitors, :matching_url, :string,                :default => "",    :null => false
    add_column :it_computer_monitors, :ranking, :integer,                    :default => 0,     :null => false
    add_column :it_computer_monitors, :search_engine, :string,               :default => "",    :null => false
    add_column :it_computer_monitors, :search_phrase, :string,               :default => "",    :null => false

    rename_table :it_computer_monitors, :odesk_listers
  end
end
