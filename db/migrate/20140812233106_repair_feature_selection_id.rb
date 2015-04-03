class RepairFeatureSelectionId < ActiveRecord::Migration
  def up
    rename_column :feature_selections, :feature_pricing_id, :feature_id
  end

  def down
    rename_column :feature_selections, :feature_id, :feature_pricing_id
  end
end
