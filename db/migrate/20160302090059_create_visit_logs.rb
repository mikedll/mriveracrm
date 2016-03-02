class CreateVisitLogs < ActiveRecord::Migration
  def up
    create_table :visit_logs do |t|
      t.string     :path,       :default => "", :null => false
      t.string     :user_agent, :default => "", :null => false
      t.string     :ip,         :default => "", :null => false
      t.string     :referer,    :default => "", :null => false
      t.timestamps
    end
  end

  def down
    drop_table :visit_logs
  end
end
