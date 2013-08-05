class Products < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.integer :business_id
      t.string  :name
      t.decimal :price
      t.boolean :active
      t.timestamps
    end

    create_table :general_images do |t|
      t.string :data
      t.timestamps
    end

    create_table :general_images_products, :id => false do |t|
      t.integer :general_image_id
      t.integer :product_id
    end
  end

  def down
    drop_table :general_images_products
    drop_table :general_images
    drop_table :products
  end
end
