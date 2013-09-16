class AddSocketTypeToConnector < ActiveRecord::Migration
  def change
    add_column :connectors, :socket_type, :string, default: 'http'
  end
end
