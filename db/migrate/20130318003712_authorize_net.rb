class AuthorizeNet < ActiveRecord::Migration
  def self.up
    create_table :payment_gateway_profiles do |t|
      t.string     :type
      t.integer    :client_id
      t.string     :vendor_id
      t.string     :card_profile_id
      t.string     :card_last_4
      t.timestamps
    end
 
    create_table :transactions do |t|
      t.integer    :invoice_id
      t.integer    :payment_gateway_profile_id
      t.string     :status
      t.decimal    :amount,     :precision => 10, :scale => 2, :default => 0.0
      t.string     :vendor_id
      t.text       :error
      t.integer    :authorizenet_gateway_response_code
      t.integer    :authorizenet_gateway_response_reason_code
      t.timestamps
    end

    create_table :detected_errors do |t|
      t.text       :message
      t.integer    :client_id
      t.integer    :business_id
      t.integer    :user_id
      t.timestamps
    end

    add_column :invoices, :description, :text
    add_column :invoices, :status, :string
    add_column :invoices, :date, :datetime
    add_column :invoices, :client_id, :integer
    add_column :invoices, :title, :string
  end

  def self.down
    remove_column :invoices, :title
    remove_column :invoices, :client_id
    remove_column :invoices, :date
    remove_column :invoices, :status
    remove_column :invoices, :description
    drop_table :detected_errors
    drop_table :transactions
    drop_table :payment_gateway_profiles
  end
end
