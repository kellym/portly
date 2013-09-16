class AddVersionToToken < ActiveRecord::Migration
  def change
    add_column :tokens, :version, :string, default: "0.0.0"
  end
end
