class StripeController < SharedController

  post '/' do
    data = JSON.parse request.body.read, :symbolize_names => true
    event = Stripe::Event.retrieve(data[:id])
    halt 404 unless event
    @result = event.data.object
    case event.type
    when 'charge.succeeded'
      charge_succeeded
    end
  end

  def charge_succeeded
    user = User.includes(:account).where('accounts.customer_id' => @result.customer).first
    if user
      time = Time.at(user.account.customer.subscription.current_period_end) + 1.day
      user.account.update_column(:billing_period, user.account.customer.subscription.plan.interval + 'ly')
      user.schedule.update_column(:good_until, time)
    end
    halt 200
  end

end
