class Transfer < ActiveRecord::Base

  # property :id, Serial
  # property :transaction_id, Integer
  # property :source_account_id, Integer
  # property :destination_account_id, Integer
  # property :amount, Decimal, precision: 12, scale: 2
  # property :created_at, DateTime
  # property :updated_at, DateTime

  belongs_to :transaction
  #belongs_to :source_account, class_name: 'Account'
  #belongs_to :destination_account, class_name: 'Account'

end
