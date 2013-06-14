class CreateUserTokensTable < ActiveRecord::Migration
  def change
    create_table :user_tokens do |t|
      t.integer :user_id
      t.integer :token_id
      t.string :code
      t.datetime :expires_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :user_tokens, :user_id
    add_index :user_tokens, :token_id
    add_index :user_tokens, :deleted_at
  end
end
