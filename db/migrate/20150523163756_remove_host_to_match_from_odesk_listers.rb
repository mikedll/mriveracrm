class RemoveHostToMatchFromOdeskListers < ActiveRecord::Migration
  def up
    remove_column :odesk_listers, :host_to_match
  end

  def down
    add_column :odesk_listers, :host_to_match, :string, :default => "", :null => false
  end
end
