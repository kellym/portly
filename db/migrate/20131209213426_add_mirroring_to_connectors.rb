class AddMirroringToConnectors < ActiveRecord::Migration
  def change
    add_column :connectors, :mirror, :boolean, default: false
  end
end
