class BusinessHasOwner < ActiveRecord::Migration
  def up
    add_column :employees, :role, :string, :null => false, :default => ""
  end

  def down
    remove_column :employees, :role
  end
end
