#!/usr/bin/env ruby

require 'pp'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'package_validator'

validator = PackageValidator.new
pp validator.validate_package(ARGV[0])
