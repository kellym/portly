class PortScraperService

  extend Queueable

  # Public: Creates a new PortScraperService model that will scrape a site with
  # wget.
  def initialize(connector, opts={})
    if connector.is_a? Connector
      @connector = connector
    else
      @connector = Connector.find(connector)
    end
    @opts = {
      #'adjust-extension'    => nil,
      #'no-directories'      => nil,
      'no-host-directories' => nil,
      'convert-links'       => nil,
      'page-requisites'     => nil,
      'random-wait'         => nil,
      'timestamping'        => nil,
      'no-check-certificate'=> nil,
      'header'              => "Accept: text/html",
      'timeout'             => 30,
      'reject'              => 'zip,mpg',
      'quota'               => '20m',
      'directory-prefix'    => "#{App.config.cache_path}#{@connector.id}"
    }.merge opts
    if @connector.has_authentication?
      user = @connector.auths.first
      if user
        @opts['user'] = user.username
        @opts['password'] = user.password
      end
    end
  end

  def perform
    return unless @connector.mirror?
    command = "wget"
    @opts.each do |action, value|
      if value
        command += %[ --#{action}="#{value}"]
      else
        command +=" --#{action}"
      end
    end
    command += " #{@connector.public_url.gsub(/^https\:/,'http:')}"
    Redis.current.set("#{@connector.id}:syncing", true)
    EventSource.publish(@connector.user_id, 'sync', id: @connector.id, state: 'started')
    system command
    EventSource.publish(@connector.user_id, 'sync', id: @connector.id, state: 'completed')
  ensure
    Redis.current.del("#{@connector.id}:syncing")
  end

end
