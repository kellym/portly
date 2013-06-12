class Transaction < ActiveRecord::Base

  # property :id, Serial
  # property :description, String, length: 128
  # property :log_type, String, length: 20
  # property :type, String, length: 20
  # property :state, String, length: 20
  # property :tracking_code, String, length: 20
  # property :created_at, DateTime
  # property :updated_at, DateTime
  # property :refunded_at, DateTime

  belongs_to :account

end
