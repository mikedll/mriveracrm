class BusinessesHaveGoogleApiKey < ActiveRecord::Migration
  def up
    add_column :businesses, :google_public_api_key, :string, :default => "", :null => false
  end

  def down
    remove_column :business, :google_public_api_key
  end
end
