class Order < ActiveRecord::Base

  # property :id, Serial
  # property :user_id, Integer
  # property :account_id, Integer
  # property :transaction_id, Integer
  # property :schedule_id, Integer
  # property :amount, Decimal, precision: 12, scale: 2
  # property :state, String, length: 20
  # property :completed_at, DateTime
  # property :created_at, DateTime
  # property :updated_at, DateTime

  belongs_to :user
  belongs_to :account
  belongs_to :transaction
  belongs_to :schedule
end

