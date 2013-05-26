class AddComputerModelToToken < ActiveRecord::Migration
  def change
    add_column :tokens, :computer_model, :string
  end
end
