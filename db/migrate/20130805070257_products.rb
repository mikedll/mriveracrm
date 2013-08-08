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

    execute "update images set business_id = (select id from businesses where domain = 'www.mikedll.com')"
    
  end

  def down
    remove_column :images, :business_id
    drop_table :product_images
    drop_table :products
  end
end
