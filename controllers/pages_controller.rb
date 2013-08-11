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
      render :'pages/show', :layout => nil,
        locals: {
          content: connector.closest_page ? connector.closest_page.content : nil,
          logo: connector.closest_page && connector.closest_page.cover_image_uid ? connector.closest_page.cover_image.thumb('400x400#').url : nil,
        }
    else
      halt 404
    end
  end

end

