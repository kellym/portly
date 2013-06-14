class SharedController < Scorched::Controller

  config[:show_http_error_pages] = false
  render_defaults << { :engine => :haml, :layout => :'layouts/application' }

  include ViewHelpers

  def media_type
    @media_type ||= MediaType.new(env['HTTP_ACCEPT'])
  end

  after do
    response.headers['Content-Type'] = media_type.to_s
  end

end
