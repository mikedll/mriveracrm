class AuthorizeNet < ActiveRecord::Migration
  def self.up
    create_table :payment_gateway_profiles do |t|
      t.integer    :client_id
      t.string     :type
      t.string     :vendor_id
      t.timestamps
    end
 
    create_table :transactions do |t|
      t.integer         :invoice_id
      t.integer         :payment_gateway_profile_id
      t.string          :vendor_payment_gateway_profile_id
      t.decimal         :amount,     :precision => 10, :scale => 2, :default => 0.0
      t.string          :vendor_id
      t.text            :error
      t.integer         :authorizenet_gateway_response_code
      t.integer         :authorizenet_gateway_response_reason_code
    end
  end

  def self.down
    drop_table :transactions
    drop_table :payment_gateway_profiles
  end
end
