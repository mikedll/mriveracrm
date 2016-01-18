class CreatePages < ActiveRecord::Migration
  def up
    create_table :pages do |t|
      t.integer      :business_id,   :null => false
      t.string       :title,         :default => "", :null => false
      t.string       :slug,          :default => "", :null => false
      t.boolean      :active,        :default => false, :null => false
      t.text         :body,          :default => "", :null => false
      t.text         :compiled_body, :default => "", :null => false
      t.integer      :link_priority, :null => false
      t.timestamps
    end

    create_table :link_orderings do |t|
      t.references :business,        :null => false
      t.string     :scope,           :default => "", :null => false
      t.string     :referenced_link, :default => "", :null => false
      t.integer    :priority,        :null => false
      t.timestamps
    end
  end

  def down
    drop_table :link_orderings
    drop_table :pages
  end
end
