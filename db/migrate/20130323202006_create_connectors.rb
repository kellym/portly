class CreateConnectors < ActiveRecord::Migration
  def change
    create_table :connectors do |t|
      t.integer :user_id
      t.string :user_host, length: 255
      t.integer :user_port
      t.string :user_ip
      t.integer :token_id
      t.string :connection_string
      t.string :subdomain, unique: true
      t.string :cname, unique: true
      t.string :auth_type
      t.boolean :connected, default: false
    end
    add_index :connectors, :user_id
    add_index :connectors, :token_id
    add_index :connectors, :subdomain
    add_index :connectors, :cname
  end

end
