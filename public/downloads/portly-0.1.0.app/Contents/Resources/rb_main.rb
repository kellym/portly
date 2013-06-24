#
#  rb_main.rb
#  port
#
#  Created by Kelly Martin on 3/3/13.
#  Copyright (c) 2013 Kelly Martin. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'CoreFoundation'
framework 'Cocoa'
framework 'Sparkle'
framework 'Security'

#require 'rubygems'
require 'json'
require 'socket'

JSON.parser = JSON::Ext::Parser

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

def NSLocalizedString(key)
    NSBundle.mainBundle.localizedStringForKey(key, value:'', table:nil)
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
