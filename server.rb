#!/usr/bin/env ruby

require 'sinatra'
require 'cgi'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'package_validator'
require 'external_provenance_extractor'
require 'auto_incrementer'
require 'libxml'


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
            URI.parse params[:location]
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


  # Expects a query parameter named location to be a cgi escaped uri
  # of a package. Currently only file urls are supported.
  # Returns 400 if there is a problem with the URI.
  get '/external_provenance' do

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

    # all clean, pull the external provenance
    extractor = ExternalProvenanceExtractor.new
    @external_p = extractor.extract_provenance url.path
    erb :external_provenance
  end
end

Validation.run! if __FILE__ == $0
