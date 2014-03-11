class UseHostsNotDomains < ActiveRecord::Migration
  def up
    rename_column :businesses, :domain, :host
    rename_column :marketing_front_ends, :domain, :host
  end

  def down
    rename_column :businesses, :host, :domain
    rename_column :marketing_front_ends, :host, :domain
  end
end
