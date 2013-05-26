class AddMacAddressToTokens < ActiveRecord::Migration
  def change
    add_column :tokens, :mac_address, :string
  end
end
