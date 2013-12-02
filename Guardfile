# A sample Guardfile
# More info at https://github.com/guard/guard#readme
require './config/dependencies'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require './config/settings'

guard :shell do
  watch(%r{^(views\/(.+(\.handlebars\.haml)))}) { |m|
    `cp #{m[1]} assets/templates/#{m[2].gsub('/','.')}`
  }
end

guard 'haml', default_ext: 'handlebars', input: 'assets/templates', output: 'assets/templates' do
  watch %r{^assets\/templates\/.+(\.handlebars\.haml)}
end

guard 'handlebars', input: 'assets/templates', output: 'assets/javascripts/templates', shallow: true do
  watch(/^.+(\.html)?(\.handlebars)$/)
end
