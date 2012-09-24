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
      t.timestamps
    end

    create_table :image_projects do |t|
      t.string :image_id
      t.string :project_id
    end

  end

  def self.down
    drop_table :image_projects
    drop_table :images
    drop_table :projects
  end
end
