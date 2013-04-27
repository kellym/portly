class AddRemoteFlagToTokens < ActiveRecord::Migration
  def change
    add_column :tokens, :allow_remote, :boolean, default: true
  end
end
