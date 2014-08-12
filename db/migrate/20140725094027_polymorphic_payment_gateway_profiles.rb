class PolymorphicPaymentGatewayProfiles < ActiveRecord::Migration
  def up
    rename_column :payment_gateway_profiles, :client_id, :payment_gateway_profilable_id
    add_column :payment_gateway_profiles, :payment_gateway_profilable_type, :string, :default => '', :null => false

    execute "UPDATE payment_gateway_profiles SET type = 'Client'"

    remove_column :usage_subscriptions, :card_brand
    remove_column :usage_subscriptions, :card_last_4
    remove_column :usage_subscriptions, :remote_id
  end

  def down
    add_column :usage_subscriptions, :remote_id,   :string,  :null => false, :default => ""
    add_column :usage_subscriptions, :card_brand,  :string,  :null => false, :default => ""
    add_column :usage_subscriptions, :card_last_4, :string,  :null => false, :default => ""

    remove_column :payment_gateway_profiles, :payment_gateway_profilable_type
    rename_column :payment_gateway_profiles, :payment_gateway_profilable_id, :client_id
  end
end
