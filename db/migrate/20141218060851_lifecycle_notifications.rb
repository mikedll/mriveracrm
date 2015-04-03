class LifecycleNotifications < ActiveRecord::Migration
  def up
    create_table :lifecycle_notifications do |t|
      t.integer    :business_id,   :null => false, :default => 0
      t.string     :identifier,    :null => false, :default => ""
      t.timestamps
    end
  end

  def down
    drop_table :lifecycle_notifications
  end
end
