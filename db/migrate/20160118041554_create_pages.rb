class CreatePages < ActiveRecord::Migration
  def up
    create_table :pages do |t|
      t.integer      :business_id,   :null => false
      t.string       :title,         :default => "", :null => false
      t.string       :slug,          :default => "", :null => false
      t.boolean      :active,        :null => false
      t.text         :body,          :default => "", :null => false
      t.text         :compiled_body, :default => "", :null => false
      t.timestamps
    end
  end

  def down
    drop_table :pages
  end
end
