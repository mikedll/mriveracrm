class BusinessesHaveITMonitoredComputersKey < ActiveRecord::Migration
  def up
    add_column :businesses, :it_monitored_computers_key, :string, :default => ""
  end

  def down
    remove_column :businesses, :it_monitored_computers_key
  end
end
