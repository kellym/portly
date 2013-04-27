class CreateUsersAndAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :code
      t.decimal :balance, precision: 12, scale: 2
      t.string :state, length: 20, default: 'active'
      t.integer :plan_id
      t.integer :admin_id
      t.timestamps
    end
    add_index :accounts, :admin_id
    add_index :accounts, :code

    create_table :users do |t|
      t.integer :account_id
      t.string :email, :unique => true, :length => 128
      t.string :encrypted_password, :length => 128
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :state, :length => 20, default: 'active'
      t.timestamps
    end
    add_index :users, :email
    add_index :users, :account_id
  end
end
