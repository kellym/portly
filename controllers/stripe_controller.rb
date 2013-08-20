class StripeController < SharedController

  post '/' do
    data = JSON.parse request.body.read, :symbolize_names => true
    event = Stripe::Event.retrieve(data[:id])
    @event = event.data.object
    case event.type
    when 'charge.succeeded'
      charge_succeeded
    end
  end

  def charge_succeeded
    user = User.joins(:account).where('accounts.customer_id' => @event.customer).first
  end

end
