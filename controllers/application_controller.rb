SOCKETS = Hash.new {|h, k| h[k] = [] }

class ApplicationController < Scorched::Controller

  config[:show_http_error_pages] = false
  render_defaults << { :engine => :haml, :layout => :'layouts/application' }

  include Middleware
  include ViewHelpers

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

  # Public: The homepage for the site.
  get '/' do
    if signed_in?
      redirect '/tunnels'
    else
      render :homepage
    end
  end

  get '/tunnels' do
    authenticate_user!
    render :tunnels, :layout => :'layouts/user'
  end

  get '/subscribe/tunnels' do |channel|
    authenticate_user!
    body = EventSource.new(current_user.id)
    SOCKETS[current_user.id] << body
    request.env['async.callback'].call [200, {'X-Accel-Buffering' => 'no', 'Content-Type' => 'text/event-stream'}, body]
    throw :async
  end

  get '/publish_tunnel/:channel' do |channel|
    SOCKETS[channel].send(request[:data]) if SOCKETS.include?(channel)
    'done'
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

