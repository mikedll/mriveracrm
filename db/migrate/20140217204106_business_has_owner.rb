class BusinessHasOwner < ActiveRecord::Migration
  def up
    add_column :employees, :role, :string, :null => false, :default => ""
    add_column :businesses, :handle, :string, :null => false, :default => ""
  end

  def down
    remove_column :businesses, :handle
    remove_column :employees, :role
  end
end
