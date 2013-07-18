class RemoveMicroPlan < ActiveRecord::Migration
  def up
    Account.where(:plan_id => 1).update_all(:plan_id => 2)
    Plan.find(1).destroy
  end
  def down
  end
end
