class AddPathToConnectors < ActiveRecord::Migration
  def change
    add_column :connectors, :path, :string
  end
end
