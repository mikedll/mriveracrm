class RemoveBetaTesters < ActiveRecord::Migration
  def up
    drop_table :beta_testers
  end

  def down
    create_table :beta_testers do |t|
      t.string :email
      t.timestamps
    end
  end
end
