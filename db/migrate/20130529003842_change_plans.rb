class ChangePlans < ActiveRecord::Migration
  def change
    add_column :plans, :bandwidth, :integer
    add_column :plans, :tunnel_limit, :integer
    remove_column :plans, :user_limit
  end
end
