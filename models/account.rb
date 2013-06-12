class Account < ActiveRecord::Base

  belongs_to :plan
  belongs_to :admin, class_name: 'User'
  has_many :users
  has_many :transactions

  before_create :generate_account_code

  def bonus_months
    (self.balance.to_f / self.plan.monthly).to_i
  end

  # Internal: Generates the unique account code for internal referencing.
  def generate_account_code
    self.code ||= loop do
      token = SecureRandom.hex(10)
      break token unless self.class.where(code: token).exists?
    end
  end

end
