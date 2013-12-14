class AddCouponToInvite < ActiveRecord::Migration
  def change
    add_column :affiliates, :coupon, :string
    add_column :affiliates, :trial_length, :integer
    add_column :affiliates, :description, :string
  end
end
