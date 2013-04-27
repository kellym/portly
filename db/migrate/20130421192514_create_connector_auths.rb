class CreateConnectorAuths < ActiveRecord::Migration
  def change
    create_table :connector_auths do |t|
      t.integer :connector_id
      t.string :username
      t.string :password
    end
    add_index :connector_auths, :connector_id
  end
end
