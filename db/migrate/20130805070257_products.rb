class Products < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.integer :business_id
      t.string  :name
      t.decimal :price
      t.boolean :active
      t.timestamps
    end

    create_table :images_products, :id => false do |t|
      t.integer :image_id
      t.integer :product_id
    end

    add_column :images, :business_id, :integer

    execute "update images set business_id = (select id from businesses where domain = 'www.mikedll.com')"
    
  end

  def down
    remove_column :images, :business_id
    drop_table :images_products
    drop_table :products
  end
end
