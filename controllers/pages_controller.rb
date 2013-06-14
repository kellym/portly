class PagesController < SharedController

  get '/offline' do
    server_name = request.env['HTTP_HOST']
    connector = Connector.where('subdomain = ? OR cname = ?', server_name, server_name).first
    if connector
      render connector.closest_page.content, layout: :'layouts/page'
    else
      halt 404
    end
  end

end

