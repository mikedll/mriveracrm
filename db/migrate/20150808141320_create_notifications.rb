class CreateNotifications < ActiveRecord::Migration
  def up
    create_table :notifications do |t|
      t.integer :business_id, :default => 0, :null => false
      t.string  :identifier,  :default => "", :null => false
      t.string  :to,          :default => "", :null => false
      t.string  :from,        :default => "", :null => false
      t.string  :subject,     :default => "", :null => false
      t.text    :body,        :default => "", :null => false
      t.timestamps
    end
  end

  def down
    drop_table :notifications
  end
end
