class AddTrialEndToSchedule < ActiveRecord::Migration
  def change
    add_column :schedules, :trial_end, :datetime
  end
end
