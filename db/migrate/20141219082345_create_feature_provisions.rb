class CreateFeatureProvisions < ActiveRecord::Migration
  def up
    create_table :feature_provisions do |t|
      t.integer :feature_id, :null => false, :default => 0
      t.integer :marketing_front_end_id, :null => false, :default => 0
      t.timestamps
    end
  end

  def down
    drop_table :feature_provisions
  end
end
