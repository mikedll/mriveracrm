class CreateUsageSubscriptions < ActiveRecord::Migration
  def up
    create_table :usage_subscriptions do |t|
      t.integer :business_id,   :null => false, :default => 0
      t.string  :card_brand,    :null => false, :default => ""
      t.string  :card_last_4,   :null => false, :default => ""
      t.string  :plan,          :null => false, :default => ""
      t.string  :remote_id,     :null => false, :default => ""
      t.string  :remote_status, :null => false, :default => ""
      t.timestamps
    end
  end

  def down
    drop_table :usage_subscriptions
  end
end
