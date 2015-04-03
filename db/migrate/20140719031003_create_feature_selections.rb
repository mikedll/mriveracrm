class CreateFeatureSelections < ActiveRecord::Migration
  def change
    create_table :feature_selections do |t|
      t.integer :feature_pricing_id,     :null => false, :default => 0
      t.integer :usage_subscription_id,  :null => false, :default => 0
      t.timestamps
    end
  end
end
