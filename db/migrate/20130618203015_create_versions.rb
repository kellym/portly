class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.string :version
      t.string :dsa
      t.integer :filesize
      t.string :title
      t.text :notes
      t.timestamps
    end
  end
end
