class RenameCustomerToCustomerIdOnAccounts < ActiveRecord::Migration
  def change
    rename_column :accounts, :customer, :customer_id
  end
end
