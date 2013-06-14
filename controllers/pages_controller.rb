class PagesController < SharedController

  get '/offline' do
    server_name = request.env['HTTP_HOST']
    if server_name =~ /\.portly\.co$/
      server_name.gsub!(/\.[^\.]*\.portly\.co$/,'')
      connector = Connector.where(:subdomain => server_name).first
    else
      connector = Connector.where(:cname => server_name).first
    end
    if connector
      render connector.closest_page.content, layout: :'layouts/page'
    else
      halt 404
    end
  end

end

