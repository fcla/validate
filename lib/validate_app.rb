#!/usr/bin/env ruby

require 'sinatra'
require 'wip/sip_descriptor'
require 'datafile/checksum'

# if we want to rack multiple sinatras up we need to have them separate
module Validation

  class App < Sinatra::Base
    set :root, File.join(File.dirname(__FILE__), '..')

    # Expects a query parameter named location to be a cgi escaped uri
    # of a package. Currently only file urls are supported.
    # Returns 400 if there is a problem with the URI.
    get '/results' do
      error 400, "Missing parameter: location" unless params[:location]

      # parse location into a url
      url = begin
              URI.parse params[:location]
            rescue => e
              error 400, "Ill-formed url: #{params[:location]}"
            end

      # for now only support file
      error 400, "Unsupported URL scheme: #{url.scheme}" unless url.scheme == 'file'

      @wip = begin 
              Wip.new url.path, 'test:/'
            rescue => e
              error 400, e
            end

      erb :results
    end

  end

end

Validation:App.run! if __FILE__ == $0
