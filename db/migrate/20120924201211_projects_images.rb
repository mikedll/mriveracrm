class ProjectsImages < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :title
      t.string :link
      t.text :description
      t.string :tech
      t.timestamps
    end

    create_table :images do |t|
      t.string :data
      t.string :project_id
      t.timestamps
    end

  end

  def self.down
    drop_table :images
    drop_table :projects
  end
end
