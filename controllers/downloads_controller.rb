class DownloadsController < SharedController

  get '/sparkle_updates.xml' do
    @versions = Version.all
    render :'downloads/sparkle_updates.xml', layout: nil
  end

end
