class PlanUpdaterService

  def initialize(user)
    @user = user
  end

  def update(opts = {})

    # Set up Billing Period
    @user.account.billing_period = opts[:billing_period]

    # Determine Plan. If invite-only, force them to free if not invited.
    plan = Plan.where(reference: opts[:plan]).first
    if plan && plan.invite_required? && !Invite.where(user_id: @user.id, plan_id: plan.id).exists?
      plan = nil
    end

    # If the plan doesn't exist or they weren't invited, use the free pan.
    plan ||= @user.plan.where(reference: 'free').first

    if !plan.free? && @user.account.card.nil?
      return false
    else
      @user.account.plan = plan
      response = @user.account.customer.update_subscription(plan: @user.account.stripe_plan)
      if response
        begin
          Stripe::Invoice.create(
            customer: @user.account.customer_id
          )
        rescue Stripe::InvalidRequestError
        end
        @user.account.save

        # update the schedule with the new plan
        @user.schedule.update_attributes(plan_id: plan.id, good_until: Time.at(response.current_period_end.to_i))

        # activate the user
        @user.activate!

        # delete any raw sockets if they switched to free
        if plan.free?
          @user.connectors.update_all(socket_type: 'http', server_port: nil)
        end

        # Add/remove tokens from the free_plan list.
        @user.tokens.each do |token|
          token.authorized_key.save_to_file if token.authorized_key
          Redis.current.publish("socket:#{token.code}", "plan:#{plan.name.downcase}")
          if plan.free?
            Redis.current.sadd 'free_plan', token.code
          else
            Redis.current.srem 'free_plan', token.code
          end
        end
        return true
      end
    end
    false
  end

end
