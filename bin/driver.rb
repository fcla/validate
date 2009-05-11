#!/usr/bin/env ruby

require 'package_validator'
require 'pp'

validator = PackageValidator.new

pp validator.validate_package(ARGV[0])
