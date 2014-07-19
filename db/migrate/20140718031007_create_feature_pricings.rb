class CreateFeaturePricings < ActiveRecord::Migration
  def self.up
    create_table :feature_pricings do |t|
      t.integer :feature_id,    :null => false, :default => 0
      t.decimal :price,         :null => false, :precision => 10, :scale => 2, :default => 0.0
      t.integer :generation,    :null => false, :default => 0
      t.timestamps
    end

    create_table :features do |t|
      t.integer :bit_index,     :null => false, :default => 0
      t.string  :feature_name,  :null => false, :default => ""
      t.timestamps
    end

  end

  def self.down
    drop_table :features
    drop_table :feature_pricings
  end

end
