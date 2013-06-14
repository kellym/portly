class PagesController < SharedController

  get '/offline' do
    server_name = request.env['HTTP_HOST']
    connector = Connector.where('subdomain = ? OR cname = ?', server_name, server_name).first
    if connector
      connector.closest_page.content
    else
      request.env.inspect
    end
  end

end

