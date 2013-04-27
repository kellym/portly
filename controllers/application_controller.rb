class ApplicationController < Scorched::Controller

  render_defaults << { :engine => :haml, :layout => :'layouts/application' }

  include Middleware

  def current_user
    env['warden'].user
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
    render :signin
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
    authenticate_user!
    redirect '/', 302
  end

  get '/signup' do
    render :signup
  end

  post '/signup' do
    @user = User.new(request[:user])
    if @user.save
      env['warden'].set_user @user
      redirect '/', 302
    else
      flash[:error] = @user.errors.join '.'
      render :signup
    end
  end

  get '/hello' do
    'hello'
  end

  get '/' do
    current_user ? current_user.email : 'Hello.'
  end

  self << {pattern: '/api', priority: 10, target: ApiController}

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

