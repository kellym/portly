class SeparateConnectorBytes < ActiveRecord::Migration
  def change
    rename_column :connector_bytes, :bytes, :bytes_total
    add_column :connector_bytes, :bytes_in, 'bigint'
    add_column :connector_bytes, :bytes_out, 'bigint'
    add_index :connector_bytes, :connector_id
  end
end
