#!/usr/bin/env ruby

require 'sinatra'
require 'package_validator'

# if package is on localhost, validates package and returns the XML report.
# if the package is on any other host, responds to request with 501.

def validate uri_path
  # check our provided path.
  # we expect a URL of the form file://localhost/path/to/package
  # if host is not localhost, respond with 501.
  if uri_path =~ /^file:\/\/localhost/
    local_path = uri_path.gsub(/^file:\/\/localhost/, "")
  else
    not_implemented
  end

  validator = PackageValidator.new
  validator.validate_package(local_path)
end

# responds to request with a 501 - Not Implemented
def not_implemented
  halt 501, "I don't know how to pull packages from the cloud yet"
end

# /validate is exposed, and expects a GET variable "location" containing a URI to a package
# to validate.
# Returns a 400 if location GET variable is missing, or if URI begins with anything but http:// and file://
# Returns a 501 if URI begins with http://
# Attempts to validate package if URI begins with file://
get '/validate' do
  if params[:location] =~ /^file:\/\//
    validate params[:location]
  elsif params[:location] =~ /^http:\/\//
    not_implemented
  else
    halt 400, "Missing parameter: location"
  end
end
