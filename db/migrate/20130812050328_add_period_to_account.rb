class AddPeriodToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :billing_period, :string, default: 'monthly'
  end
end
