class CreateSeoRankers < ActiveRecord::Migration
  def up
    create_table :seo_rankers do |t|
      t.integer  :business_id,               :null => false
      t.string   :name,                      :null => false, :default => ""
      t.datetime :last_window_started_at,    :null => false
      t.integer  :runs_since_window_started, :null => false, :default => 0
      t.string   :search_phrase,             :null => false, :default => ""
      t.string   :search_engine,             :null => false, :default => ""
      t.integer  :ranking,                   :null => false, :default => 0
      t.timestamps
    end
  end

  def down
    drop_table :seo_rankers
  end
end
