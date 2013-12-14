class UserCreationService
  def initialize(user_klass = User, mailer_klass = UserMailer)
    @user_klass = user_klass
    @mailer_klass  = mailer_klass
  end

  def create(params)
    @user_klass.create(params).tap do |u|
      if u.persisted?
        @mailer_klass.signup u.id
        u.invite.mark_as_used_by(u) if u.invite
        customer = Stripe::Customer.create(
          :description => u.id
        )
        u.account.set_customer(customer)
        u.activate!
        if u.invite
          subscription = {
            plan: u.account.stripe_plan
          }
          subscription[:coupon] = u.invite.affiliate.coupon if u.invite.affiliate.coupon
          subscription[:trial_end] = u.invite.affiliate.trial_length.days.from_now.to_i if u.invite.affiliate.trial_length.to_i > 0
          puts subscription.inspect
          customer.update_subscription(subscription)
        end
      end
    end
  end
end
