class CreateFeaturePricings < ActiveRecord::Migration
  def change
    create_table :feature_pricings do |t|
      t.integer :index,         :null => false, :default => 0
      t.decimal :price,         :null =>, :precision => 10, :scale => 2, :default => 0.0
      t.string  :release,       :null =>, :default => ""
      t.string  :feature_name,  :null =>, :default => ""
      t.timestamps
    end
  end
end
