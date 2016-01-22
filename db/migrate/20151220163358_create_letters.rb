class CreateLetters < ActiveRecord::Migration
  def up
    create_table :letters do |t|
      t.integer :business_id, :null => false
      t.string  :title
      t.text    :body
    end
  end

  def down
    drop_table :letters
  end
end
