require_relative 'shared_controller'
Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/api/base_controller.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/api/*.rb'].each {|file| require file }

SOCKETS = Hash.new {|h, k| h[k] = [] }

class ApplicationController < SharedController

  get '/changelogsentme' do
    invite = InviteCreationService.new.create(affiliate_id: 2)
    session[:invite_id] = invite.id
    redirect '/', 302
  end

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
    env['warden'].logout if signed_in?
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
        redirect '/dashboard', 302
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
      end
      if session[:invite_id]
        invite = Invite.includes(:affiliate => :plan).find(session[:invite_id])
        if invite
          @plan ||= invite.affiliate.plan
          @special = invite.affiliate.description
        end
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
      invite_free = false
      if session[:invite_id]
        invite = Invite.find(session[:invite_id])
        session.delete :invite_id
        invite_free = invite.affiliate.trial_length.to_i > 0
      end
      env['warden'].set_user @user, :event => :authentication
      session[:new_user] = true
      if @user.plan.free? || invite_free
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
      @file = File.read(filename, File.size(filename)).lines
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
    if request[:id]
      card_updater = CardUpdaterService.new(current_user)
      if card_updater.create(request[:id])
        flash[:card_change] = 'Your credit card has been updated.'
      end
    elsif request[:exp_mo] && request[:exp_yr]
      card_updater = CardUpdaterService.new(current_user)
      if card_updater.update(request)
        flash[:card_change] = 'Your card expiration date has been updated.'
      end
    end

    if request[:plan]
      plan_updater = PlanUpdaterService.new(current_user)
      if plan_updater.update(plan: request[:plan], billing_period: request[:billing_period])
        flash[:plan_change] = 'Your current plan has been updated.'
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
