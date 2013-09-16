class AddServerPortToConnector < ActiveRecord::Migration
  def change
    add_column :connectors, :server_port, :integer
    add_index :connectors, :server_port
  end
end
