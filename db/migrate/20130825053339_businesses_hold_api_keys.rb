class BusinessesHoldApiKeys < ActiveRecord::Migration
  def up
    add_column :businesses, :stripe_secret_key, :string
    add_column :businesses, :stripe_publishable_key, :string
    add_column :businesses, :google_oauth2_client_id, :string
    add_column :businesses, :google_oauth2_client_secret, :string
    add_column :businesses, :authorizenet_payment_gateway_id, :string
    add_column :businesses, :api_login_id, :string
    add_column :businesses, :transaction_key, :string
    add_column :businesses, :test, :boolean
  end

  def down
    remove_column :businesses, :test, :boolean
    remove_column :businesses, :transaction_key, :string
    remove_column :businesses, :api_login_id, :string
    remove_column :businesses, :authorizenet_payment_gateway_id, :string
    remove_column :businesses, :google_oauth2_client_secret, :string
    remove_column :businesses, :google_oauth2_client_id, :string
    remove_column :businesses, :stripe_publishable_key, :string
    remove_column :businesses, :stripe_secret_key, :string
  end
end
