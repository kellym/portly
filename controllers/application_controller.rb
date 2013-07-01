require_relative 'shared_controller'
Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file }

SOCKETS = Hash.new {|h, k| h[k] = [] }

class ApplicationController < SharedController


  include Middleware

  def current_user
    env['warden'].user
  end

  def signed_in?
    !!env['warden'].user
  end

  def authenticate_user!
    env['warden'].authenticate! unless env['warden'].authenticated?
  end

  def api_request?
    request[:client_id] || request[:access_token]
  end

  def nginx_request?
    env['nginx_request']
  end

  get '/signin' do
    render :signin, :layout => :'layouts/marketing'
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
      redirect '/', 302
    else
      @error = 'The email or password you provided is incorrect.'
      render :signin, :layout => :'layouts/marketing'
    end
  end

  get '/signup' do
    @user = {}
    render :signup, :layout => :'layouts/marketing'
  end

  post '/signup' do
    @user = UserCreationService.new.create(request[:user])
    if @user.persisted?
      env['warden'].set_user @user
      flash[:new_user] = true
      redirect '/', 302
    else
      @form_errors = @user.errors
      @user = Hashie::Mash.new(request[:user] || {})
      render :signup, :layout => :'layouts/marketing'
    end
  end

  # Public: The homepage for the site.
  get '/' do
    if signed_in?
      redirect '/tunnels'
    else
      @html_class = 'homepage'
      render :homepage, :layout => :'layouts/marketing'
    end
  end

  get '/pricing' do
    @plans = Plan.all
    render :pricing, :layout => :'layouts/marketing'
  end

  get '/about' do
    render :about, :layout => :'layouts/marketing'
  end

  get '/tunnels' do
    authenticate_user!
    @computers = current_user.tokens.active.sort_by { |t| t.online? ? 0 : 1 }
    render :'tunnels/index'
  end

  get '/tunnels/*' do |token_id|
    authenticate_user!
    @token = Token.where(id: token_id, user_id: current_user.id)
    halt 404 unless @token
    @computers = current_user.tokens.active.sort_by { |t| (t.id == token_id.to_i) ? 0 : (t.online? ? 1 : 2) }
    @pjax = env['HTTP_X_PJAX']
    #puts env.inspect
    render :'tunnels/index', layout: (@pjax ? false : :'layouts/application')
  end

  get '/subscribe/tunnels' do |channel|
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
        ''
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

  self << {pattern: '/api', priority: 10, target: ::ApiController}
  self << {pattern: '/auth', priority: 10, target: ::AuthController}
  self << {pattern: '/pages', priority: 10, target: ::PagesController}
  self << {pattern: '/downloads', priority: 10, target: ::DownloadsController}

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

  after status: 404 do
    response.body = '404 Not Found'
    #response.body = env.inspect
  end
end
