class DownloadsController < SharedController

  get '/current' do
    v = Version.last
    redirect "/downloads/portly-#{v.version}-#{v.number}.zip"
  end

  get '/sparkle_updates.xml' do
    @versions = Version.order('created_at desc').all
    render :'downloads/sparkle_updates.xml', layout: nil
  end

end
