class Account < ActiveRecord::Base

  belongs_to :plan
  belongs_to :admin, class_name: 'User'
  has_many :users
  has_many :transactions
  belongs_to :card

  before_create :generate_account_code

  def customer
    return nil unless customer?
    @customer ||= Stripe::Customer.retrieve(customer_id)
  end

  def customer?
    customer_id?
  end

  def set_customer(customer)
    self.customer_id = customer.id
    @customer = customer
    self.update_customer
  end

  def update_customer
    self.card.destroy if self.card
    # we have to reload the customer because the default card probably
    # changed
    @customer = Stripe::Customer.retrieve(customer_id)
    if customer.default_card
      c = customer.cards.retrieve(customer.default_card)
      self.create_card(card_id: c.id, last4: c.last4, card_type: c.type, exp_month: c.exp_month, exp_year: c.exp_year)
    end
    self.save
  end

  # Public: This gets the record associated with the account on file from Stripe.
  #
  # Returns a Stripe::Card.
  def stripe_card
    @stripe_card ||= customer.cards.retrieve(card.card_id)
  end

  # Internal: Generates the unique account code for internal referencing.
  def generate_account_code
    self.code ||= loop do
      token = SecureRandom.hex(10)
      break token unless self.class.where(code: token).exists?
    end
  end

end
