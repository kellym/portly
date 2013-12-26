class Account < ActiveRecord::Base

  belongs_to :plan
  belongs_to :admin, class_name: 'User'
  has_many :users
  has_many :transactions
  belongs_to :card

  before_create :generate_account_code
  after_save :update_redis_data

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

  # Public: Set the billing period to one of the two correct options.
  def billing_period=(period)
    if %w(monthly yearly).include? period.to_s
      super
    else
      super 'monthly'
    end
  end

  # Public: This returns the name of the stripe plan.
  def stripe_plan
    if self.plan && !self.plan.gratis?
      "#{self.plan.reference}_#{self.billing_period || 'monthly'}"
    else
      "free"
    end
  end

  # Internal: Generates the unique account code for internal referencing.
  def generate_account_code
    self.code ||= loop do
      token = SecureRandom.hex(10)
      break token unless self.class.where(code: token).exists?
    end
  end

  # Internal: Removes any data that may be remaining around a free
  # plan.
  def update_redis_data
    if plan.free?
      admin.tokens.each do |token|
        Redis.current.sadd 'free_plan', token
      end
    else
      admin.tokens.each do |token|
        Redis.current.srem 'free_plan', token
      end
    end
    true
  end
end
