class BusinessHasSplashInfo < ActiveRecord::Migration
  def up
    add_column :businesses, :splash_html, :text, :default => "", :null => false
    add_column :businesses, :contact_text, :text, :default => "", :null => false
  end

  def down
    remove_column :businesses, :contact_text
    remove_column :businesses, :splash_html
  end
end
