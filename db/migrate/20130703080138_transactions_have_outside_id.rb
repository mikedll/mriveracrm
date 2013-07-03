class TransactionsHaveOutsideId < ActiveRecord::Migration
  def up
    add_column :transactions, :type, :string
    execute "update transactions set type = 'StripeTransaction'"
    change_column :transactions, :type, :string, :null => false

    add_column :transactions, :outside_id, :string
    add_column :transactions, :outside_vendor, :string
  end

  def down
    remove_column :transactions, :outside_vendor
    remove_column :transactions, :outside_id
    remove_column :transactions, :type
  end
end
