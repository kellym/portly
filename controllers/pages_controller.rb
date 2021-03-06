class PagesController < SharedController

  get '/offline' do
    server_name = request.env['HTTP_HOST']
    if server_name =~ /\.portly\.co$/
      server_name.gsub!(/([^\.]*)\.portly\.co$/,'')
      server_name, match, subdomain = $1.rpartition('-')
      if server_name
        connector = Connector.joins(:user).where(users: { subdomain: subdomain}, subdomain: server_name).first
      else
        subdomain = server_name
        server_name = ''
        connector = Connector.joins(:user).where(users: { subdomain: subdomain}, subdomain: server_name).first
      end
    end
    unless connector
      connector = Connector.where(:cname => server_name).first
    end
    if connector
      if connector.mirror?
        @path = request[:__portly_request_uri]
        if request.env['QUERY_STRING'].length + 22 > @path.length
          @query_string = request.env['QUERY_STRING'][@path.length+22..-1]
          @path = "#{@path}?#{@query_string}" if @query_string && @query_string.length > 0
        end
        @path = "#{App.config.cache_path}#{connector.id}#{@path}"
        if File.directory?(@path)
          @path = @path.sub(/(\/)+\Z/, '') + "/index.html"
        end
        if !File.exists?(@path)
          self.custom_404 = render(:'pages/show', :layout => nil, locals: { content: nil, logo: nil })
          halt 404
        end
        #puts @path
        last_modified = File.mtime(@path).httpdate
        halt 304 if env['HTTP_IF_MODIFIED_SINCE'] == last_modified
        response.headers["Last-Modified"] = last_modified
        mime = Rack::Mime.mime_type(File.extname(@path), 'text/html')
        self.media_type = mime if mime

        # NOTE:
        #   We check via File::size? whether this file provides size info
        #   via stat (e.g. /proc files often don't), otherwise we have to
        #   figure it out by reading the whole file into memory.
        size = File.size?(@path) || Rack::Utils.bytesize(File.read(@path))

        ranges = Rack::Utils.byte_ranges(env, size)
        if ranges.nil? || ranges.length > 1
          # No ranges, or multiple ranges (which we don't support):
          # TODO: Support multiple byte-ranges
          response.status = 200
          @range = 0..size-1
        elsif ranges.empty?
          # Unsatisfiable. Return error, and file size:
          response.headers["Content-Range"] = "bytes */#{size}"
          halt 416
        else
          # Partial content:
          @range = ranges[0]
          response.status = 206
          response.headers["Content-Range"] = "bytes #{@range.begin}-#{@range.end}/#{size}"
          size = @range.end - @range.begin + 1
        end

        response.headers["Content-Length"] = size.to_s
        response.body = File.read(@path)
      else
        render :'pages/show', :layout => nil,
          locals: {
            content: connector.closest_page ? connector.closest_page.content : nil,
            logo: connector.closest_page && connector.closest_page.cover_image_uid ? connector.closest_page.cover_image.thumb('400x400#').url : nil,
          }
      end
    else
      if subdomain && (user = User.where(:subdomain => subdomain).first)
        render :'pages/show', :layout => nil,
        locals: {
          content: user.page ? user.page.content : nil,
          logo: user.page && user.page.cover_image_uid ? user.page.cover_image.thumb('400x400#').url : nil,
        }
      else
        halt 404
      end
    end
  end

end

