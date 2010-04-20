#!/usr/bin/env ruby

require 'sinatra'
require 'virus'
require 'daitss/config'

# if we want to rack multiple sinatras up we need to have them separate
module Validation

  class App < Sinatra::Base

    post '/*' do
      Daitss::CONFIG.load ENV['CONFIG']

      # return 400 if there is no body in the request
      request.body.rewind
      halt 400, "Missing body" if request.body.size == 0

      # write body to a tempfile
      tf = Tempfile.new rand(1000)

      while (buffer = request.body.read 1048576)
        tf << buffer
      end

      tf.rewind

      @path = tf.path

      erb :results
    end

  end

end

Validation:App.run! if __FILE__ == $0
