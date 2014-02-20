class CreateMarketingFrontEnds < ActiveRecord::Migration
  def up
    create_table :marketing_front_ends do |t|
      t.string :title,                       :default => "", :null => false
      t.string :domain,                      :default => "", :null => false
      t.string :google_oauth2_client_id,     :default => "", :null => false
      t.string :google_oauth2_client_secret, :default => "", :null => false
      t.timestamps
    end

    d = Rails.env.production? ? 'www.mikedllcrm.com' : 'devmarketing.mikedllcrm.com'
    execute "insert into marketing_front_ends (title, domain, created_at, updated_at) values ('Mikedll CRM', '#{d}', now(), now())"

    execute "update businesses set handle = 'mikedll' where domain = 'www.mikedll.com'"
  end

  def down
    drop_table :marketing_front_ends
  end
end
