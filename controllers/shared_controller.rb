class SharedController < Scorched::Controller

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

  before do
    env['warden'].authenticate unless env['warden'].authenticated?
  end


  def custom_404=(val)
    @custom_404 = val
  end

  def media_type
    @media_type ||= MediaType.new(env['HTTP_ACCEPT'])
  end

  def media_type=(val)
    @media_type = val
  end

  # Flash session storage helper.
  # Stores session data until the next time this method is called with the same arguments, at which point it's reset.
  # The typical use case is to provide feedback to the user on the previous action they performed.
  def flash(key = :flash)
    raise Error, "Flash session data cannot be used without a valid Rack session" unless session
    flash_hash = env['scorched.flash'] ||= {}
    flash_hash[key] ||= {}
    flash_session ||= {}
    flash_session[key] ||= session[key] || {}
    unless flash_session[key].methods(false).include? :[]=
      flash_session[key].define_singleton_method(:[]=) do |k, v|
        flash_hash[key][k] = v
      end
    end
    flash_session[key]
  end

  after do
    env['scorched.flash'].each { |k,v| session[k] = v } if session && env['scorched.flash']
    response.headers['Content-Type'] = media_type.to_s
  end

  after status: 404 do
    response.body = @custom_404 || render(:'errors/show', layout: :'layouts/marketing')
  end

  after status: 500 do
    response.body = render :'errors/show', layout: :'layouts/marketing'
  end

end
