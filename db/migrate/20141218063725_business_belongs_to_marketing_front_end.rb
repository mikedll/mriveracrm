class BusinessBelongsToMarketingFrontEnd < ActiveRecord::Migration
  def up
    add_column :businesses, :default_mfe_id, :integer,  :null => false, :default => 0

    mfehost = Rails.env.production? ? 'www.mriveracrm.com' : 'devmarketing.mriveracrm.com'
    execute "UPDATE businesses SET default_mfe_id = (select id from marketing_front_ends where host = '#{mfehost}')"
  end

  def down
    remove_column :businesses, :default_mfe_id
  end
end
