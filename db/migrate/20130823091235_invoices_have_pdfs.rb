class InvoicesHavePdfs < ActiveRecord::Migration
  def up
    add_column :invoices, :pdf_file, :string
  end

  def down
    remove_column :invoices, :pdf_file
  end
end
