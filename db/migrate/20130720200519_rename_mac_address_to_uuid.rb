class RenameMacAddressToUuid < ActiveRecord::Migration
  def change
    rename_column :tokens, :mac_address, :uuid
  end
end
