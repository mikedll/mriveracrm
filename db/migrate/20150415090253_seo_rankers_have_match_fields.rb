class SEORankersHaveMatchFields < ActiveRecord::Migration
  def up
    add_column :seo_rankers, :host_to_match, :string, :default => "", :null => false
    add_column :seo_rankers, :last_error, :string, :default => "", :null => false

    add_column :seo_rankers, :matching_url, :string, :default => "", :null => false
    add_column :seo_rankers, :matching_title, :string, :default => "", :null => false
  end

  def down
    remove_column :seo_rankers, :matching_title
    remove_column :seo_rankers, :matching_url

    remove_column :seo_rankers, :last_error
    remove_column :seo_rankers, :host_to_match
  end
end
