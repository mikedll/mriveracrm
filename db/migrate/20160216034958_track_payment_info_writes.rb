class TrackPaymentInfoWrites < ActiveRecord::Migration
  def up
    add_column :payment_gateway_profiles, :payment_info_last_written, :datetime
  end

  def down
    remove_column :payment_gateway_profiles, :payment_info_last_written
  end
end
