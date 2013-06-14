class CreatePagesTable < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.text :content
      t.string :cover_image_uid
      t.boolean :default, default: false
    end
    add_column :tokens, :page_id, :integer
    add_column :connectors, :page_id, :integer
    add_column :users, :page_id, :integer
    remove_column :connectors, :cover_image_uid
    add_index :tokens, :page_id
    add_index :connectors, :page_id
    add_index :users, :page_id
  end
end
