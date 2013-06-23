class DownloadsController < SharedController

  render_defaults << { :engine => :haml, :layout => nil }

  get '/sparkle_updates.xml' do
    @versions = Version.all
    render :'downloads/sparkle_updates.xml'
  end

end
