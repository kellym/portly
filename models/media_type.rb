class MediaType

  def initialize(http_accept)
    @media_type ||= http_accept.split(',',2).first.split('/',2).last.to_sym
  end

  def ==(type)
    @media_type == type.to_sym
  end

  def json?
    @json ||= @media_type == :json
  end

  def html?
    @html ||= @media_type == :html
  end

  def to_s
    if @media_type == :html
      'text/html'
    else
      "application/#{@media_type.to_s}"
    end
  end

end
