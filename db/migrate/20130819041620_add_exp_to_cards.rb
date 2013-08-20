class AddExpToCards < ActiveRecord::Migration
  def change
    rename_column :cards, :type, :card_type
    add_column :cards, :card_id, :string
    add_column :cards, :exp_month, :string
    add_column :cards, :exp_year, :string
  end
end
