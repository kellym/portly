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
      'adjust-extension'    => nil,
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

    @opts[:directory] ||= "#{App.config.cache_path}#{@connector.id}"
    if %w(friend unlimited).include? @connector.user.plan.reference
      @opts['mirror'] = nil
      @opts['quota']  = '100m'
    end
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
    command += " #{@connector.public_url}"
    Redis.current.set("#{@connector.id}:syncing", true)
    EventSource.publish(@connector.user_id, 'sync', id: @connector.id, state: 'started')

    #@uri = URI.parse(@connector.public_url)
    crawl_site(@connector.public_url) do |contents, uri|
      @uri = uri
      @contents = contents
    #  source = html_get(@uri)
    #  @contents = Nokogiri::HTML( source )
      process_contents
      save_locally(@opts[:directory])
    end

    EventSource.publish(@connector.user_id, 'sync', id: @connector.id, state: 'completed')
  ensure
    Redis.current.del("#{@connector.id}:syncing")
  end


  def crawl_site( starting_at, &each_page )
    #files = %w[png jpeg jpg gif svg txt js css zip gz]
    starting_uri = URI.parse(starting_at)
    @seen_pages = Set.new                      # Keep track of what we've seen

    crawl_page = ->(page_uri) do              # A re-usable mini-function
      unless @seen_pages.include?(page_uri)
        @seen_pages << page_uri                # Record that we've seen this
        begin
          puts page_uri.inspect
          doc = Nokogiri.HTML(html_get(page_uri)) # Get the page
          each_page.call(doc,page_uri)        # Yield page and URI to the block

          # Find all the links on the page
          hrefs = doc.css('a[href]').map{ |a| a['href'] }

          # Make these URIs, throwing out problem ones like mailto:
          uris = hrefs.map{ |href| URI.join( page_uri, href ) rescue nil }.compact

          # Pare it down to only those pages that are on the same site
          uris.select!{ |uri| uri.host.empty? || (uri.host == starting_uri.host) }

          # Throw out links to files (this could be more efficient with regex)
          # uris.reject!{ |uri| files.any?{ |ext| uri.path.end_with?(".#{ext}") } }

          # Remove #foo fragments so that sub-page links aren't differentiated
          uris.each{ |uri| uri.fragment = nil }

          # Recursively crawl the child URIs
          uris.each do |uri|
            uri.host = starting_uri.host
            crawl_page.call(uri)
          end

        rescue #OpenURI::HTTPError # Guard against 404s
          warn "Skipping invalid link #{page_uri}"
        end
      end
    end

    crawl_page.call( starting_uri )   # Kick it all off!
  end

  attr_reader :uri
  attr_reader :contents
  attr_reader :css_tags, :js_tags, :img_tags, :meta, :links

=begin rdoc
Extract resources (CSS, JS, Image files) from the parsed html document.
=end
  def process_contents
    @css_tags = @contents.xpath( '//link[@rel="stylesheet"]' )
    @js_tags = @contents.xpath('//script[@src]')
    @img_tags = @contents.xpath( '//img[@src]' )
    # Note: meta tags and links are unused in this example
    find_meta_tags
    find_links
  end


=begin rdoc
Extract contents of META tags to @meta Hash.
=end
  def find_meta_tags
    @meta = {}
    @contents.xpath('//meta').each do |tag|
      last_name = name = value = nil
      tag.attributes.each do |key, attr|
        if attr.name == 'content'
          value = attr.value
        elsif attr.name == 'name'
          name = attr.value
        else
          last_name = attr.value
        end
      end
      name = last_name if not name
      @meta[name] = value if name && value
    end
  end


=begin rdoc
Generate a Hash URL -> Title of all (unique) links in document.
=end
  def find_links
    @links = {}
    @contents.xpath('//a[@href]').each do |tag|
      @links[tag[:href]] = (tag[:title] || '') if (! @links.include? tag[:href])
    end
  end


=begin rdoc
Generate a local, legal filename for url in dir.
=end
  def localize_url(url, dir)
    path = url.gsub(/^[|[:alpha]]+:\/\//, '')
    path.gsub!(/^[.\/]+/, '')
    path.gsub!(/[^-_.\/[:alnum:]]/, '_')
    File.join(dir, path)
  end


=begin rdoc
Construct a valid URL for an HREF or SRC parameter. This uses the document URI
to convert a relative URL ('/doc') to an absolute one ('http://foo.com/doc').
=end
  def url_for(str)
    return str if str =~ /^[|[:alpha:]]+:\/\//
    File.join((uri.path.empty?) ? uri.to_s : File.dirname(uri.to_s), str)
  end


=begin rdoc
Send GET to url, following redirects if required.
=end
  def html_get(url)
    puts url.inspect
    resp = Net::HTTP.get_response(url)
    if ['301', '302', '307'].include? resp.code
      new_url = URI.parse resp['location']
      puts 'new: '
      puts new_url.inspect
      if new_url.host.nil?
        new_url = URI.join "#{url.scheme}://#{url.host}", resp['location']
        url = new_url
      else
        url = new_url
      end
    elsif resp.code.to_i >= 400
      $stderr.puts "[#{resp.code}] #{url}"
      return
    end
    Net::HTTP.get url
  end


=begin rdoc
Download a remote file and save it to the specified path
=end
  def download_resource(url)
    FileUtils.mkdir_p "#{@opts[:directory]}#{File.dirname(url.path)}"
    data = html_get url
    File.open("#{@opts[:directory]}#{url.path}", 'wb') { |f| f.write(data) } if data
  end


=begin rdoc
Download resource for attribute 'sym' in 'tag' (e.g. :src in IMG), saving it to
'dir' and modifying the tag attribute to reflect the new, local location.
=end
  def localize(tag, sym, dir)
    delay
    url = tag[sym]
    url_parsed = URI.parse(url)
    if url_parsed.host.nil?
      url_parsed = URI.join "#{uri.scheme}://#{uri.host}", url
    elsif url_parsed.host != uri.host
      return
    end
    return if @seen_pages.include? url_parsed
    @seen_pages << url_parsed
    download_resource(url_parsed)
    #tag[sym.to_s] = url.partition(File.dirname(dir) + File::SEPARATOR).last
  end


=begin rdoc
Attempt to "play nice" with web servers by sleeping for a few ms.
=end
  def delay
    sleep(rand / 100)
  end


=begin rdoc
Download all resources to destination directory, rewriting in-document tags
to reflect the new resource location, then save the localized document.
Creates destination directory if it does not exist.
=end
  def save_locally(dir)
    #Dir.mkdir(dir) if (! File.exist? dir)

    # remove HTML BASE tag if it exists
    @contents.xpath('//base').each { |t| t.remove }


    # save resources
    @img_tags.each { |tag| localize(tag, :src, File.join(dir, 'images')) }
    @js_tags.each { |tag| localize(tag, :src, File.join(dir, 'js')) }
    @css_tags.each { |tag| localize(tag, :href, File.join(dir, 'css')) }

    basename = File.basename(uri.path)
    if (uri.query.nil? || uri.query == '') && File.extname(basename) == ''
      folder = uri.path.sub(/(\/)+$/,'')
      basename = "/index.html"
    else
      folder = uri.path.to_s.sub(/\/#{basename}\Z/, '')
    end
    basename += "?#{uri.query}" if uri.query.present?
    FileUtils.mkdir_p "#{@opts[:directory]}#{folder}"
    save_path = File.join("#{@opts[:directory]}#{folder}", basename)
    File.open(save_path, 'w') { |f| f.write(@contents.to_html) }
  end

end
