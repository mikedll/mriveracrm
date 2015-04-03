class SimplerFeatureName < ActiveRecord::Migration
  def up
    rename_column :features, :feature_name, :name
    add_column    :features, :public_name, :string, :default => "", :null => false
  end

  def down
    remove_column :features, :public_name
    rename_column :features, :name, :feature_name
  end
end
