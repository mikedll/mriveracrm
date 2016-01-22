class Products < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.integer :business_id
      t.string  :name, :null => false, :default => ""
      t.text    :description, :null => false, :default => ""
      t.decimal :price
      t.float   :weight
      t.string  :weight_units, :null => false, :default => ""
      t.boolean :active, :null => false, :default => false
      t.timestamps
    end

    create_table :product_images do |t|
      t.integer :image_id
      t.integer :product_id
      t.boolean :active, :default => false, :null => false
      t.boolean :primary, :default => false, :null => false
      t.timestamps
    end

    add_column :images, :business_id, :integer
    add_column :images, :data_original_filename, :string
    add_column :images, :data_unique_id, :string

  end

  def down
    remove_column :images, :data_unique_id
    remove_column :images, :data_original_filename
    remove_column :images, :business_id
    drop_table :product_images
    drop_table :products
  end
end
