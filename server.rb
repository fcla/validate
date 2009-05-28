#!/usr/bin/env ruby

require 'sinatra'
require 'cgi'
require 'package_validator'
require 'auto_incrementer'

# if we want to rack multiple sinatras up we need to have them separate
class Validation < Sinatra::Default
  
  # Expects a query parameter named location to be a cgi escaped uri
  # of a package. Currently only file urls are supported.
  # Returns 400 if there is a problem with the URI.
  get '/' do
    
    # make sure location exists
    halt 400, "Missing parameter: location" unless params[:location]

    # parse location into a url
    url = begin
            raw_url = CGI::unescape params[:location]
            URI.parse raw_url
          rescue => e
            halt 400, "Ill-formed url: #{raw_url}"
          end

    # for now only support file
    halt 400, "Unsupported URL scheme: #{url.scheme}" unless url.scheme == 'file'

    # all clean, validate
    validator = PackageValidator.new
    @result = validator.validate_package url.path
    @auto_incrementer = AutoIncrementer.new
    erb :validation_events
  end

end

Validation.run! if __FILE__ == $0
