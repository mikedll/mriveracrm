class InvoicesHavePdfs < ActiveRecord::Migration
  def up
    add_column :invoices, :pdf_file, :string
    add_column :invoices, :pdf_file_unique_id, :string
    add_column :invoices, :pdf_file_original_filename, :string
  end

  def down
    remove_column :invoices, :pdf_file_original_filename
    remove_column :invoices, :pdf_file_unique_id
    remove_column :invoices, :pdf_file
  end
end
