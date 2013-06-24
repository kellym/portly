#
#  Connector.rb
#  port
#
#  Created by Kelly Martin on 3/26/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

module Api
  class Base

    def self.connector
      @connector ||= Faraday.new App.api_endpoint do |conn|
        conn.request :multipart
        conn.use Faraday::Response::Logger     # log request & response to STDOUT
        conn.use Faraday::Adapter::NetHttp     # perform requests with Net::HTTP
        #conn.adapter Faraday.default_adapter
        conn.use FaradayMiddleware::Mashify
      #conn.use FaradayMiddleware::ParseJson
      end
    end

  end

end