class PolymorphicPaymentGatewayProfiles < ActiveRecord::Migration
  def up
    rename_column :payment_gateway_profiles, :client_id, :payment_gateway_profilable_id
    add_column :payment_gateway_profiles, :payment_gateway_profilable_type, :integer, :default => 0, :null => false

    execute "UPDATE payment_gateway_profiles SET type = 'Client'"
  end

  def down
    remove_column :payment_gateway_profiles, :payment_gateway_profilable_type
    rename_column :payment_gateway_profiles, :payment_gateway_profilable_id, :client_id
  end
end
