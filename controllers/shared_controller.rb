class SharedController < Scorched::Controller

  def media_type
    @media_type ||= MediaType.new(env['HTTP_ACCEPT'])
  end

  after do
    response.headers['Content-Type'] = media_type.to_s
  end

end
