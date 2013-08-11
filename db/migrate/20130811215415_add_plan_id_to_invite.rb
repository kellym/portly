class AddPlanIdToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :plan_id, :integer
  end
end
