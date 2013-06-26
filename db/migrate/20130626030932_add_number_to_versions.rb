class AddNumberToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :number, :integer
  end
end
