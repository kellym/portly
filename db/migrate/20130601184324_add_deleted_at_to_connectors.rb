class AddDeletedAtToConnectors < ActiveRecord::Migration
  def change
    add_column :connectors, :deleted_at, :datetime
  end
end
