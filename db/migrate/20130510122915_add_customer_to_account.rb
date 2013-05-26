class AddCustomerToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :customer, :string
  end
end
