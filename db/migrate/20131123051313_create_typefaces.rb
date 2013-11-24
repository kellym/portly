class CreateTypefaces < ActiveRecord::Migration
  def change
    create_table :typefaces do |t|
      t.string :name
      t.string :family_name
      t.string :family_id
      t.string :variation_id
    end
    create_table :kits do |t|
      t.string :reference
      t.integer_array :typefaces
    end
    add_index :typefaces, :family_name
    add_column :connectors, :kit_id, :integer
  end
end
