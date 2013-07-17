class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.integer :last4
      t.string :type
    end
    add_column :accounts, :card_id, :integer
  end
end
