class CreateBusinesses < ActiveRecord::Migration
  def self.up
    create_table :businesses do |t|
      t.string :name,      :default => "", :null => false
      t.string :domain,    :default => "", :null => false
      t.timestamps
    end

    execute "insert into businesses (name, domain) values ('The Mike De La Loza Company', 'www.mikedll.com')"

    create_table :clients do |t|
      t.string :first_name, :default => "", :null => false
      t.string :last_name, :default => "", :null => false
      t.integer :user_id
      t.timestamps
    end

    create_table :businesses_clients, :id => false do |t|
      t.integer :business_id
      t.integer :client_id
    end

    create_table :users do |t|
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
      t.timestamps
    end

    create_table :businesses_users, :id => false do |t|
      t.integer :business_id
      t.integer :user_id
    end

    create_table :credentials do |t|
      t.integer :user_id
      t.string :email,         :default => "", :null => false
      t.string :credential_id
      t.string :oauth_token
      t.string :oauth_secret
      t.timestamps
    end

    create_table :invoices do |t|
      t.integer :business_id
      t.decimal :total
      t.timestamps
    end

    create_table :payment_gateway_profiles do |t|
      t.integer :user_id
      t.timestamps
    end

    add_column :projects, :user_id, :integer

  end

  def self.down
    remove_column :projects, :user_id    
    drop_table :payment_gateway_profiles
    drop_table :invoices
    drop_table :credentials
    drop_table :businesses_users
    drop_table :users
    drop_table :businesses_clients
    drop_table :clients
    drop_table :businesses
  end
end
