class AddInviteReqToPlan < ActiveRecord::Migration
  def up
    add_column :plans, :invite_required, :boolean, default: false
    Plan.reset_column_information
    Plan.where(:id => [5, 6]).update_all(:invite_required => true)
  end

  def down
  end
end
