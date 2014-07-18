class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :key        :null => false, :default => ""
      t.string :value,     :null => false, :default => ""
      t.string :value_type :null => false, :default => "String"
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute "insert into settings (key, value, value_type) values ('Release', '1.6')"
      end
    end
  end
end
