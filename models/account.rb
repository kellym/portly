class Account < ActiveRecord::Base

  belongs_to :plan
  belongs_to :admin, class_name: 'User'
  has_many :users

  before_create :generate_account_code

  # Internal: Generates the unique account code for internal referencing.
  def generate_account_code
    self.code ||= loop do
      token = SecureRandom.hex(10)
      break token unless self.class.where(code: token).exists?
    end
  end

end
