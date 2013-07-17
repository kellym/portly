class Account < ActiveRecord::Base

  belongs_to :plan
  belongs_to :admin, class_name: 'User'
  has_many :users
  has_many :transactions
  belongs_to :card

  before_create :generate_account_code

  def customer?
    customer_id?
  end

  def bonus_months
    (self.balance.to_f / self.plan.monthly).to_i
  end

  def set_customer(customer)
    self.customer_id = customer.id
    self.card.destroy if self.card
    if customer.default_card
      c = customer.cards.retrieve(customer.default_card)
      self.create_card(last4: c.last4, type: c.type)
    end
    self.save
  end

  # Internal: Generates the unique account code for internal referencing.
  def generate_account_code
    self.code ||= loop do
      token = SecureRandom.hex(10)
      break token unless self.class.where(code: token).exists?
    end
  end

end
