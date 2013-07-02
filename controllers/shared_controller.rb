class SharedController < Scorched::Controller

  config[:show_http_error_pages] = false
  render_defaults << { :engine => :haml, :layout => :'layouts/application' }

  include ViewHelpers

  def media_type
    @media_type ||= MediaType.new(env['HTTP_ACCEPT'])
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

end
