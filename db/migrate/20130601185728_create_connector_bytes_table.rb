class CreateConnectorBytesTable < ActiveRecord::Migration
  def change
    create_table :connector_bytes do |t|
      t.integer :connector_id
      t.column :bytes, 'bigint'
      t.datetime :created_at
    end
  end
end
