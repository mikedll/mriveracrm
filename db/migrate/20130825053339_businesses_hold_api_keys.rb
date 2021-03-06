class BusinessesHoldAPIKeys < ActiveRecord::Migration
  def up
    add_column :businesses, :stripe_secret_key, :string, :null => false, :default => ""
    add_column :businesses, :stripe_publishable_key, :string, :null => false, :default => ""
    add_column :businesses, :google_oauth2_client_id, :string, :null => false, :default => ""
    add_column :businesses, :google_oauth2_client_secret, :string, :null => false, :default => ""
    add_column :businesses, :authorizenet_payment_gateway_id, :string, :null => false, :default => ""
    add_column :businesses, :authorizenet_api_login_id, :string, :null => false, :default => ""
    add_column :businesses, :authorizenet_transaction_key, :string, :null => false, :default => ""
    add_column :businesses, :authorizenet_test, :boolean, :null => false, :default => false
  end

  def down
    remove_column :businesses, :authorizenet_test
    remove_column :businesses, :authorizenet_transaction_key
    remove_column :businesses, :authorizenet_api_login_id
    remove_column :businesses, :authorizenet_payment_gateway_id
    remove_column :businesses, :google_oauth2_client_secret
    remove_column :businesses, :google_oauth2_client_id
    remove_column :businesses, :stripe_publishable_key
    remove_column :businesses, :stripe_secret_key
  end
end
