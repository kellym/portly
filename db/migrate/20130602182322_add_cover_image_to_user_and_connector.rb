class AddCoverImageToUserAndConnector < ActiveRecord::Migration
  def change
    add_column :users, :cover_image_uid, :string
    add_column :connectors, :cover_image_uid, :string
  end
end
