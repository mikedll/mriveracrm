class CreateMarketingFrontEnds < ActiveRecord::Migration
  def up
    create_table :marketing_front_ends do |t|
      t.string :title,                       :default => "", :null => false
      t.string :domain,                      :default => "", :null => false
      t.string :google_oauth2_client_id,     :default => "", :null => false
      t.string :google_oauth2_client_secret, :default => "", :null => false
      t.timestamps
    end
  end

  def down
    drop_table :marketing_front_ends
  end
end
