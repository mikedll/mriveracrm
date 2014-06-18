class ScopeUserIndicesToBusinesses < ActiveRecord::Migration
  def up
    remove_index :users, :email
    remove_index :users, :reset_password_token
    remove_index :users, :confirmation_token
    add_index :users, [:business_id, :email],                :unique => true
    add_index :users, [:business_id, :reset_password_token], :unique => true
    add_index :users, [:business_id, :confirmation_token],   :unique => true
  end

  def down
    remove_index :users, [:business_id, :email]
    remove_index :users, [:business_id, :reset_password_token]
    remove_index :users, [:business_id, :confirmation_token]
    add_index :users, :email,                   :unique => true
    add_index :users, :reset_password_token,    :unique => true
    add_index :users, :confirmation_token,      :unique => true
  end
end
