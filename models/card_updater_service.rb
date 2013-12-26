class CardUpdaterService

  def initialize(user)
    @user = user
  end

  def create(card_id)
    customer = @user.account.customer
    customer.card = card_id
    response = customer.save
    if response && @user.account.update_customer
      true
    else
      false
    end
  end

  def update(opts={})
    if opts[:exp_mo].to_i == @user.account.card.exp_month.to_i && opts[:exp_yr].to_i == @user.account.card.exp_year.to_i
      false
    else
      @user.account.stripe_card.exp_month = opts[:exp_mo].to_i
      @user.account.stripe_card.exp_year = opts[:exp_yr].to_i
      @user.account.stripe_card.save
      @user.account.update_customer
    end
  end
end
