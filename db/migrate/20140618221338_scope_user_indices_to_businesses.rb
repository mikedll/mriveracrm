class ScopeUserIndicesToBusinesses < ActiveRecord::Migration
  def up
    remove_index :users, :email
    remove_index :users, :reset_password_token
    remove_index :users, :confirmation_token
    add_index :users, [:business_id, :email],                :unique => true
    add_index :users, [:business_id, :reset_password_token], :unique => true
    add_index :users, [:business_id, :confirmation_token],   :unique => true


    remove_index "credentials", :name => "index_credentials_on_email"
    add_index :credentials, [:business_id, :email], :unique => true
  end

  def down
    remove_index :credentials, [:business_id, :email]
    add_index "credentials", ["email"], :name => "index_credentials_on_email", :unique => true



    remove_index :users, [:business_id, :email]
    remove_index :users, [:business_id, :reset_password_token]
    remove_index :users, [:business_id, :confirmation_token]
    add_index :users, :email,                   :unique => true
    add_index :users, :reset_password_token,    :unique => true
    add_index :users, :confirmation_token,      :unique => true
  end
end
