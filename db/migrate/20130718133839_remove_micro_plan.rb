class RemoveMicroPlan < ActiveRecord::Migration
  def up
    Account.where(:plan_id => 1).update_all(:plan_id => 2)
    p = Plan.where(id:1).first
    p.destroy if p
  end
  def down
  end
end
