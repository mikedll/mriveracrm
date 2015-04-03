class LifecycleNotificationsHaveBody < ActiveRecord::Migration
  def up
    add_column :lifecycle_notifications, :body, :text, :default => "", :null => false
  end

  def down
    remove_column :lifecycle_notifications, :body
  end
end
