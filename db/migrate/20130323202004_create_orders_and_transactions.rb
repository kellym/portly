class CreateOrdersAndTransactions < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name, length: 50
      t.string :reference, length: 20, unique: true
      t.decimal :monthly, precision: 12, scale: 2
      t.decimal :yearly, precision: 12, scale: 2
      t.integer :user_limit, :min => 0, :max => 65536
      t.integer :computer_limit, :min => 0, :max => 65536
    end
    add_index :plans, :reference

    create_table :orders do |t|
      t.integer :user_id
      t.integer :account_id
      t.integer :transaction_id
      t.integer :schedule_id
      t.decimal :amount, precision: 12, scale: 2
      t.string :state, length: 20
      t.datetime :completed_at
      t.timestamps
    end
    add_index :orders, :user_id
    add_index :orders, :account_id
    add_index :orders, :transaction_id

    create_table :schedules do |t|
      t.datetime :good_until
      t.integer :user_id
      t.integer :plan_id
      t.datetime :retry_on
      t.integer :retries
      t.string :state, length: 20, default: 'active'
      t.integer :billing_cycle, :default => 1
      t.timestamps
    end
    add_index :schedules, :user_id

    create_table :transactions do |t|
      t.string :description, length: 128
      t.string :log_type, length: 20
      t.string :type, length: 20
      t.string :state, length: 20
      t.string :tracking_code, length: 20
      t.timestamps
    end

    create_table :transfers do |t|
      t.integer :transaction_id
      t.integer :source_account_id
      t.integer :destination_account_id
      t.decimal :amount, precision: 12, scale: 2
      t.timestamps
    end
    add_index :transfers, :transaction_id
    add_index :transfers, :source_account_id
    add_index :transfers, :destination_account_id
  end

end
