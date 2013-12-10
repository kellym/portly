require_relative 'shared_controller'
Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/api/base_controller.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/api/*.rb'].each {|file| require file }

SOCKETS = Hash.new {|h, k| h[k] = [] }

class ApplicationController < SharedController

  get '/signin' do
    if signed_in?
      redirect '/dashboard'
    else
      @remember_me = cookie(:'user.remember.token') ? true : false
      @user = {}
      @plan = request[:plan]
      render :signin, :layout => :'layouts/minimal'
    end
  end

  get '/signout' do
    env['warden'].logout
    redirect '/'
  end

  post '/unauthenticated' do
    if api_request?
      halt 401
    elsif nginx_request?
      response.header['WWW-Authenticate'] = 'Basic realm="Restricted"'
      response.status = 401
      'Not Authorized'
    else
      flash[:error]= 'You must be signed in.'
      redirect '/signin', 302
    end
  end

  post '/signin' do
    @user = Hashie::Mash.new(request[:user] || {})
    if User.authenticate(request[:user]['email'], request[:user]['password'])
      authenticate_user!
      if request[:user]['remember_me']
        cookie :'user.remember.token', value: current_user.generate_remember_token!, expires: 2.weeks.from_now
      end
      if request[:plan] && request[:plan] != ''
        session[:plan] = request[:plan]
        redirect '/billing', 302
      else
        redirect '/', 302
      end
    else
      @error = 'The email or password you provided is incorrect.'
      @plan = request[:plan]
      render :signin, :layout => :'layouts/minimal'
    end
  end

  get '/signup' do
    if signed_in?
      redirect '/dashboard'
    else
      @user = {}
      if request[:plan]
        @plan = Plan.where(reference: request[:plan], invite_required: false).first
      elsif session[:invite_id]
        invite = Invite.includes(:affiliate => :plan).find(session[:invite_id])
        @plan = invite.affiliate.plan if invite
      end
      #@plan ||= Plan.free

      render :signup, :layout => :'layouts/minimal'
    end
  end

  post '/signup' do
    if request[:user] && session[:invite_id]
      request[:user][:invite_id] = session[:invite_id]
    end
    free_id = Plan.free.id
    free_plan_chosen = request[:user]['plan_id'] && (request[:user]['plan_id'].to_i == free_id)
    request[:user]['plan_id'] ||= free_id
    @user = UserCreationService.new.create(request[:user])
    if @user.persisted?
      session.delete :invite_id if session[:invite_id]
      env['warden'].set_user @user, :event => :authentication
      session[:new_user] = true
      if @user.plan.free?
        redirect '/tunnels', 302
      elsif @user.plan.id != free_id
        redirect '/billing', 302
      else
        redirect '/plans', 302
      end
    else
      @form_errors = @user.errors
      @user = Hashie::Mash.new(request[:user] || {})
      @plan = Plan.find(request[:user]['plan_id']) || Plan.free
      render :signup, :layout => :'layouts/minimal'
    end
  end

  get '/billing' do
    if signed_in?
      @plan = (session[:plan] && Plan.where(reference: session[:plan]).first) || current_user.plan
      @plan ||= Plan.where(reference: 'free').first

      render :billing
    else
      redirect '/', 302
    end
  end

  get '/reset-password/*' do |token|
    halt 404 unless token
    @user = User.where(:reset_password_token => token).first
    @token = token
    if @user
      render :'account/reset_password', :layout => :'layouts/minimal'
    else
      halt 404
    end
  end

  get '/reset-password' do
    render :'account/reset_password', :layout => :'layouts/minimal'
  end

  post '/reset-password' do
    halt 404 unless request[:token] || request[:user]
    if request[:token]
      @user = User.where(:reset_password_token => request[:token]).first
      if @user
        @token = request[:token]
        if @user.update_password(request[:user])
          env['warden'].set_user @user, scope: :user
          redirect '/', 302
        else
          @form_errors = @user.errors
          render :'account/reset_password', :layout => :'layouts/minimal'
        end
      else
        halt 404
      end
    else
      @user = User.where(:email => request[:user]['email']).first
      if @user
        @user.reset_password!
        @show_logo = true
        render :'account/reset_password_sent', :layout => :'layouts/minimal'
      else
        @form_errors = nil #@user.errors
        render :'account/reset_password', :layout => :'layouts/minimal'
      end
    end
  end

  get '/wordpress-support' do
    redirect 'http://wordpress.org/plugins/portly-router/', 301
  end

  get '/support' do
    render :support, :layout => user_layout
  end

  def parse_blog(page)
    filename = "./blog/#{page}"
    if File.exists?(filename)
      @file = File.read(filename).lines
      @title = @file.shift.chomp
      @meta_description = @file.shift.chomp
      @file
    else
      throw :pass
    end
  end

  get '/blog' do |page|
    parse_blog('index.html')
    @index = true
    render :blog, :layout => user_layout
  end

  get '/blog/**' do |page|
    parse_blog("blog/#{page.gsub(/[^0-9a-zA-Z\-\_\/]/,'')}/index.html")
    render :blog, :layout => user_layout
  end

  get '/terms' do
    render :terms, :layout => user_layout
  end

  # Public: The homepage for the site.
  get '/' do
    @html_class = 'homepage'
    render :homepage, :layout => nil
  end

  get '/upgrade' do
    request[:plan] ||= 'pro'
    if signed_in?
      session[:plan] = request[:plan]
      redirect '/billing', 302
    else
      redirect "/signin?plan=#{request[:plan]}", 302
    end
  end

  get '/download' do
    @show_logo = true
    render :'downloads/index', :layout => :'layouts/minimal'
  end

  get '/pricing' do
    redirect '/plans', 301
  end

  get '/tunnels' do
    redirect '/dashboard', 301
  end

  get '/plans' do
    @plans = Plan.order(:monthly).all
    @show_logo = true
    render :plans, :layout => signed_in? ? :'layouts/application' : :'layouts/marketing'
  end

  get '/about' do
    render :about, :layout => :'layouts/marketing'
  end

  get '/subscribe/ports' do |channel|
    authenticate_user!
    body = EventSource.new(current_user.id)
    SOCKETS[current_user.id] << body
    request.env['async.callback'].call [200, {'X-Accel-Buffering' => 'no', 'Content-Type' => 'text/event-stream'}, body]
    throw :async
  end

  get '/account' do
    authenticate_user!
    render :account
  end

  post '/account' do
    authenticate_user!

    attrs = { email: request[:email] }
    if request[:password].present? || request[:password_confirmation].present?
      attrs.merge!({ password: request[:password], password_confirmation: request[:password_confirmation] })
    end
    if current_user.update_attributes(attrs)
      # success
      if media_type.html?
        redirect '/account', 302
      else
        '{}'
      end
    else
      if media_type.html?
        flash[:error] = current_user.errors.full_messages.join '.'
      else
        response.status = 400
        { errors: current_user.errors.messages }.to_json
      end
    end

  end

  get '/account/billing' do
    authenticate_user!
    render :'account/billing'
  end

  # Public: Save the credit card information to the system.
  post '/account/billing' do
    if request[:plan] || request[:id]
      if request[:plan]
        plan = Plan.where(reference: request[:plan]).first

        # set up the billing period to only allow monthly/yearly
        billing_period = request[:billing_period].to_s
        unless %w(monthly yearly).include? billing_period
          billing_period = current_user.account.billing_period || 'monthly'
        end

        # if this is an invite-only plan and they weren't invited, ship them
        # back to the free plan
        if plan && plan.invite_required? && !Invite.where(user_id: current_user.id, plan_id: plan.id).exists?
          plan = nil
        end
        plan ||= current_user.Plan.where(reference: 'free').first
        if plan.gratis?
          stripe_plan = 'free'
        else
          stripe_plan = "#{plan.reference}_#{billing_period}"
        end
      else
        stripe_plan = nil
      end

      if current_user.account.customer.present?
        current_plan_id = current_user.plan.id
        if stripe_plan
          response = current_user.account.customer.update_subscription(plan: stripe_plan, card: request[:id])
          if response
            current_user.account.update_attributes(plan_id: plan.id, billing_period: billing_period)
            current_user.schedule.update_attributes(plan_id: plan.id, good_until: Time.at(response.current_period_end.to_i) + 1.day)
            current_user.activate!
            if current_plan_id != plan.id
              flash[:plan_change] = 'Your current plan has been updated.'
              if plan.free?
                current_user.connectors.update_all(socket_type: 'http', server_port: nil)
              end
              current_user.tokens.each do |token|
                token.authorized_key.save_to_file if token.authorized_key
                Redis.current.publish("socket:#{token}", "plan:#{plan.name.downcase}")
                if plan.free?
                  Redis.current.sadd 'free_plan', token
                else
                  Redis.current.srem 'free_plan', token
                end
              end
            end
          end
        else
          customer = current_user.account.customer
          customer.card = request[:id]
          response = customer.save
          if response
            flash[:card_change] = 'Your credit card has been updated.'
          end
        end
        current_user.account.update_customer
        if stripe_plan
          begin
            Stripe::Invoice.create(
              customer: current_user.account.customer_id
            )
          rescue Stripe::InvalidRequestError
          end
        end
      else
        flash[:plan_change] = 'Your information has been saved to your account.'
        customer = Stripe::Customer.create(
          :card => request[:id],
          :description => current_user.id
        )
        current_user.account.set_customer(customer)
        current_user.account.update_attributes(plan_id: plan.id)
        current_user.schedule.update_attributes(plan_id: plan.id)
        customer.update_subscription(plan: stripe_plan)
        current_user.activate!
        if plan.free?
          current_user.connectors.update_all(socket_type: 'http', server_port: nil)
        end
        current_user.tokens.each do |token|
          token.authorized_key.save_to_file
          Redis.current.publish("socket:#{token}", "plan:#{plan.name.downcase}")
          if plan.free?
            Redis.current.sadd 'free_plan', token
          else
            Redis.current.srem 'free_plan', token
          end
        end
      end
    elsif request[:exp_mo] && request[:exp_yr]
      # update the month and year if they are different from what's on file
      unless request[:exp_mo].to_i == current_user.account.card.exp_month.to_i &&
             request[:exp_yr].to_i == current_user.account.card.exp_year.to_i
        current_user.account.stripe_card.exp_month = request[:exp_mo].to_i
        current_user.account.stripe_card.exp_year = request[:exp_yr].to_i
        current_user.account.stripe_card.save
        current_user.account.update_customer
        flash[:card_change] = 'Your card expiration date has been updated.'
      end
    end
    'true'
  end

  self << {pattern: '/api/authorizations', priority: 10, target: ::Api::AuthorizationsController}
  self << {pattern: '/api/connectors', priority: 10, target: ::Api::ConnectorsController}
  self << {pattern: '/api/keys', priority: 10, target: ::Api::KeysController}
  self << {pattern: '/api/pages', priority: 10, target: ::Api::PagesController}
  self << {pattern: '/api/tokens', priority: 10, target: ::Api::TokensController}
  self << {pattern: '/api/tunnels', priority: 10, target: ::Api::TunnelsController}
  self << {pattern: '/api/affiliates', priority: 10, target: ::Api::AffiliatesController}

  self << {pattern: '/stripe_webhook', priority: 10, target: ::StripeController}

  self << {pattern: '/auth', priority: 10, target: ::AuthController}
  self << {pattern: '/pages', priority: 10, target: ::PagesController}
  self << {pattern: '/downloads', priority: 10, target: ::DownloadsController}
  self << {pattern: '/dashboard', priority: 10, target: ::DashboardController}

  get '/invites/*' do |invite_code|
    invite = Invite.where(code: invite_code, user_id: nil).first
    if invite
      session[:invite_id] = invite.id
      redirect '/signup', 302
    else
      redirect '/'
    end
  end

  route '/basic_auth/*' do |tunnel_path|
    env['nginx_request'] = true
    env['warden'].authenticate! :basic unless env['warden'].authenticated?(:basic)
    'Success'
  end

  after status: 401 do
    response.body = '401 Unauthenticated'
  end

  after status: 403 do
    response.body = '403 Unauthorized'
  end

  def user_layout
    @show_logo = true
    signed_in? ? :'layouts/application' : :'layouts/marketing'
  end

end
