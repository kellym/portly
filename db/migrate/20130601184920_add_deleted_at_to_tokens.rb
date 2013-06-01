class AddDeletedAtToTokens < ActiveRecord::Migration
  def change
    add_column :tokens, :deleted_at, :datetime
  end
end
