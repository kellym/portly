class DownloadsController < SharedController

  get '/sparkle_updates.xml' do
    @versions = Version.order('created_at desc').all
    render :'downloads/sparkle_updates.xml', layout: nil
  end

end
