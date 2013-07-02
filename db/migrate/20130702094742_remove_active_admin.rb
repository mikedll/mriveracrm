class RemoveActiveAdmin < ActiveRecord::Migration
  def up
    drop_table :admin_users



    remove_index  :active_admin_comments, :column => [:author_type, :author_id]
    remove_index  :active_admin_comments, :column => [:namespace]
    remove_column :active_admin_comments, :namespace
    rename_column :active_admin_comments, :author_id, :admin_user_id
    rename_column :active_admin_comments, :author_type, :admin_user_type
    rename_table  :active_admin_comments, :admin_notes
    add_index     :admin_notes, [:admin_user_type, :admin_user_id]



    drop_table :admin_notes

  end

  def down
    create_table :admin_notes do |t|
      t.references :resource, :polymorphic => true, :null => false
      t.references :admin_user, :polymorphic => true
      t.text :body
      t.timestamps
    end
    add_index :admin_notes, [:resource_type, :resource_id]
    add_index :admin_notes, [:admin_user_type, :admin_user_id]



    remove_index  :admin_notes, [:admin_user_type, :admin_user_id]
    rename_table  :admin_notes, :active_admin_comments
    rename_column :active_admin_comments, :admin_user_type, :author_type
    rename_column :active_admin_comments, :admin_user_id, :author_id
    add_column    :active_admin_comments, :namespace, :string
    add_index     :active_admin_comments, [:namespace]
    add_index     :active_admin_comments, [:author_type, :author_id]

    # Update all the existing comments to the default namespace
    say "Updating any existing comments to the beezlebub namespace."
    execute "UPDATE active_admin_comments SET namespace='beezlebub'"



    # Not truely reversable, as the gem is gone.
    create_table(:admin_users) do |t|
      # t.database_authenticatable :null => false
      # t.recoverable
      # t.rememberable
      # t.trackable
      # t.encryptable
      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable
      t.timestamps
    end

    # add_index :admin_users, :email,                :unique => true
    # add_index :admin_users, :reset_password_token, :unique => true
  end
end
