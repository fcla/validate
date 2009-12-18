#!/usr/bin/env ruby

require 'sinatra'
require 'checks'

# if we want to rack multiple sinatras up we need to have them separate
module Validation

  class Service < Sinatra::Base
    set :root, File.dirname(__FILE__)

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

      wip = begin 
              Wip.new url.path 
            rescue => e
              error 400, e
            end

      # mix-in all the validation checks
      wip.extend Validation::Checks

      # map the wip to the validation results
      @result[:syntax] = wip.syntax_ok?
      @result[:account] = wip.account
      @result[:sip_descriptor_ok] = wip.sip_descriptor_ok?
      @result[:undescribed_files] = wip.undescribed_files
      @result[:virus_check] = wip.virus_check_results
      @result[:checksum_check] = wip.checksum_check

      erb :validation_events
    end

  end

end

Validation::Service.run! if __FILE__ == $0
