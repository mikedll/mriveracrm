class CreateBusinesses < ActiveRecord::Migration
  def self.up
    create_table :businesses do |t|
      t.string :name,      :default => "", :null => false
      t.string :domain,    :default => "", :null => false
      t.timestamps
    end

    execute "insert into businesses (name, domain) values ('The Mike De La Loza Company', 'www.mikedll.com')"

    create_table :clients do |t|
      t.integer :business_id
      t.string :first_name, :default => "", :null => false
      t.string :last_name,  :default => "", :null => false
      t.string :email,      :default => "", :null => false
      t.timestamps
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

    create_table :contact_relationships do |t|
      t.integer :business_id
      t.integer :client_id
      t.integer :user_id
      t.timestamps
    end

    create_table :employees do |e|
      t.integer :business_id
      t.string   :first_name,             :default => "", :null => false
      t.string   :last_name,              :default => "", :null => false
      t.string   :email,                  :default => "", :null => false
      t.timestamps
    end

    create_table :employments do |t|
      t.integer :business_id
      t.integer :employee_id
      t.integer :user_id
      t.timestamps
    end

    create_table :credentials do |t|
      t.integer :user_id
      t.string :email,         :default => "", :null => false
      t.string :credential_id
      t.string :oauth_token
      t.string :oauth_secret
      t.timestamps
    end

    add_index :credentials, :email, :unique => true

    create_table :invoices do |t|
      t.integer :business_id
      t.decimal :total
      t.timestamps
    end

    add_column :projects, :business_id, :integer

    execute "update projects set business_id = (select id from businesses where domain = 'www.mikedll.com')"

    create_table :invitations do |t|
      t.integer :business_id
      t.integer :employee_id
      t.integer :client_id
      t.string  :email, :default => "", :null => false
      t.timestamps
    end

  end

  def self.down
    drop_table :invitations
    remove_column :projects, :business_id
    drop_table :invoices
    remove_index :credentials, :column => :email
    drop_table :credentials

    drop_table :employments
    drop_table :employees

    drop_table :contact_relationships
    drop_table :users
    drop_table :clients
    drop_table :businesses
  end
end
