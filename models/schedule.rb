class Schedule < ActiveRecord::Base

  # property :id, Serial
  # property :good_until, DateTime
  # property :user_id, Integer
  # property :plan_id, Integer
  # property :retry_on, DateTime
  # property :retries, Integer
  # property :state, String, length: 20, :default => 'active'
  # property :billing_cycle, Integer, :default => 1
  # property :created_at, DateTime
  # property :updated_at, DateTime

  belongs_to :user
end
