class AddToHandleToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :handle, :string, :default => ""
  end
end
