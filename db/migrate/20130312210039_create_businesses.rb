class CreateBusinesses < ActiveRecord::Migration
  def self.up
    create_table :businesses do |t|
      t.string :name,      :default => "", :null => false
      t.string :domain,    :default => "", :null => false
      t.timestamps
    end

    create_table :clients do |t|
      t.integer :business_id
      t.string :first_name, :default => "", :null => false
      t.string :last_name,  :default => "", :null => false
      t.string :email,      :default => "", :null => false
      t.timestamps
    end

    create_table :users do |t|
      t.integer  :business_id
      t.string   :first_name,             :default => "", :null => false
      t.string   :last_name,              :default => "", :null => false
      t.string   :email,                  :default => "", :null => false
      t.integer  :sign_in_count
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      t.string   :timezone
      t.integer  :employee_id
      t.integer  :client_id
      t.timestamps
    end

    create_table :employees do |t|
      t.integer :business_id
      t.string   :first_name,             :default => "", :null => false
      t.string   :last_name,              :default => "", :null => false
      t.string   :email,                  :default => "", :null => false
      t.timestamps
    end

    create_table :credentials do |t|
      t.integer :business_id
      t.integer :user_id
      t.string :name,          :default => "", :null => false
      t.string :uid,           :default => "", :null => false
      t.string :email,         :default => "", :null => false
      t.string :provider,      :default => "", :null => false
      t.string :oauth_token
      t.string :oauth_secret
      t.string :oauth2_access_token
      t.datetime :oauth2_access_token_expires_at
      t.string :oauth2_refresh_token
      t.timestamps
    end

    add_index :credentials, :email, :unique => true

    create_table :invoices do |t|
      t.decimal :total
      t.timestamps
    end

    add_column :projects, :business_id, :integer

    create_table :invitations do |t|
      t.integer :business_id
      t.integer :employee_id
      t.integer :client_id
      t.string  :email, :default => "", :null => false
      t.string  :status
      t.timestamps
    end

  end

  def self.down
    drop_table :invitations
    remove_column :projects, :business_id
    drop_table :invoices
    remove_index :credentials, :column => :email
    drop_table :credentials
    drop_table :employees
    drop_table :users
    drop_table :clients
    drop_table :businesses
  end
end
