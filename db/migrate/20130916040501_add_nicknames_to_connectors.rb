class AddNicknamesToConnectors < ActiveRecord::Migration
  def change
    add_column :connectors, :nickname, :string
  end
end
