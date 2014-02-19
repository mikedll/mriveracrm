class CreateMarketingFrontEnds < ActiveRecord::Migration
  def up
    create_table :marketing_front_ends do |t|
      t.string :domain,                      :default => "", :null => false
      t.string :google_oauth2_client_id,     :default => "", :null => false
      t.string :google_oauth2_client_secret, :default => "", :null => false
      t.timestamps
    end

    if Rails.env.production?
      execute "insert into marketing_front_ends (domain, created_at, updated_at) values ('www.mikedllcrm.com', now(), now())"
    else
      execute "insert into marketing_front_ends (domain, created_at, updated_at) values ('devmarketing.mikedllcrm.com', now(), now())"
    end
  end

  def down
    drop_table :marketing_front_ends
  end
end
