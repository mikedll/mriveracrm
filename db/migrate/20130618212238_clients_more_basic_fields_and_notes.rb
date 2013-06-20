class ClientsMoreBasicFieldsAndNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.integer  :client_id
      t.datetime :recorded_at
      t.text     :body
      t.timestamps
    end

    add_column :clients, :website_url, :string, :null => false, :default => ""
    add_column :clients, :skype_id, :string, :null => false, :default => ""
    add_column :clients, :last_contact_at, :datetime
    add_column :clients, :next_contact_at, :datetime
    add_column :clients, :phone, :string, :null => false, :default => ""
    add_column :clients, :phone_2, :string, :null => false, :default => ""
    add_column :clients, :archived, :boolean, :null => false, :default => false
    add_column :clients, :company, :string, :null => false, :default => ""
    add_column :clients, :address_line_1, :string, :null => false, :default => ""
    add_column :clients, :address_line_2, :string, :null => false, :default => ""
    add_column :clients, :city, :string, :null => false, :default => ""
    add_column :clients, :state, :string, :null => false, :default => ""
    add_column :clients, :zip, :string, :null => false, :default => ""
  end

  def self.down
    remove_column :clients, :zip
    remove_column :clients, :state
    remove_column :clients, :city
    remove_column :clients, :address_line_2
    remove_column :clients, :address_line_1
    remove_column :clients, :company
    remove_column :clients, :archived
    remove_column :clients, :phone_2
    remove_column :clients, :phone
    remove_column :clients, :next_contact_at
    remove_column :clients, :last_contact_at
    remove_column :clients, :skype_id
    remove_column :clients, :website_url
    drop_table :notes
  end
end
