class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string :key,        :null => false, :default => ""
      t.string :value,      :null => false, :default => ""
      t.string :value_type, :null => false, :default => "String"
      t.timestamps
    end

    execute "insert into settings (key, value, value_type, created_at, updated_at) values ('Generation', '0', 'Integer', now(), now())"
  end

  def self.down
    drop_table :settings
  end
end
