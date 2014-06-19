class CreateBetaTesters < ActiveRecord::Migration
  def up
    create_table :beta_testers do |t|
      t.string :email
      t.timestamps
    end

    add_column :users, :is_admin, :boolean, :default => false
  end

  def down
    remove_column :users, :is_admin
    drop_table :beta_testers
  end
end
