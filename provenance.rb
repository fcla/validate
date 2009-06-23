#!/usr/bin/env ruby

require 'sinatra'
require 'cgi'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'external_provenance_extractor'

class Provenance < Sinatra::Base
  
  set :root, File.dirname(__FILE__)
  
  # Expects a query parameter named location to be a cgi escaped uri
  # of a package. Currently only file urls are supported.
  # Returns 400 if there is a problem with the URI.
  get '/events' do

    # make sure location exists
    halt 400, "Missing parameter: location" unless params[:location]

    # parse location into a url
    url = begin
            URI.parse params[:location]
          rescue => e
            halt 400, "Ill-formed url: #{params[:location]}"
          end

    # for now only support file
    halt 400, "Unsupported URL scheme: #{url.scheme}" unless url.scheme == 'file'

    # all clean, pull the external provenance
    extractor = ExternalProvenanceExtractor.new
    @external_p = extractor.extract_provenance url.path
    erb :external_provenance
  end
end

Provenance.run! if __FILE__ == $0
