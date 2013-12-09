# A sample Guardfile
# More info at https://github.com/guard/guard#readme
require './config/dependencies'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require './config/settings'

GuardViewHelper = Class.new do
  include ViewHelpers

  def render(file, locals={})
    Tilt.new(File.dirname(__FILE__) + '/views/' + file + ".haml").render(self, locals)
  end
end

guard :shell do
  watch(%r{^(views\/(.+(\.handlebars\.haml)))}) { |m|
    `cp #{m[1]} assets/templates/#{m[2].gsub('/','.')}`
  }

  # watch for any partials compiled and touch the files that are using them
  watch(%r{^(views\/.+\/)((\_.+)(\.haml))}) { |m|
    `grep -l -R #{m[3]} #{m[1]} | xargs touch`
  }
end

guard 'haml', default_ext: 'handlebars', input: 'assets/templates', output: 'assets/templates', scope: GuardViewHelper.new do
  watch %r{^assets\/templates\/.+(\.handlebars\.haml)}
end

guard 'handlebars', input: 'assets/templates', output: 'assets/javascripts/templates', shallow: true do
  watch(/^.+(\.html)?(\.handlebars)$/)
end
