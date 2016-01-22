class RemoveGooglePublicAPIKey < ActiveRecord::Migration
  def up
    remove_column :businesses, :google_public_api_key

    add_column :businesses, :phone, :string, :default => "", :null => false
    add_column :businesses, :address1, :string, :default => "", :null => false
    add_column :businesses, :address2, :string, :default => "", :null => false
    add_column :businesses, :city, :string, :default => "", :null => false
    add_column :businesses, :state, :string, :default => "", :null => false
    add_column :businesses, :zip, :string, :default => "", :null => false
    add_column :businesses, :email, :string, :default => "", :null => false
  end

  def down
    remove_column :businesses, :phone
    remove_column :businesses, :address1
    remove_column :businesses, :address2
    remove_column :businesses, :city
    remove_column :businesses, :state
    remove_column :businesses, :zip
    remove_column :businesses, :email

    add_column :businesses, :google_public_api_key, :string, :default => "", :null => false
  end
end
