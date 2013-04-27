class CreateTokens < ActiveRecord::Migration
  def change
    create_table :tokens do |t|
      t.integer :user_id
      t.string :computer_name, length: 255
      t.string :code
      t.datetime :expires_at
      t.timestamps
    end
    add_index :tokens, :user_id
  end
end
