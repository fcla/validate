require 'yaml'
require 'singleton'

# Class Configuration
# Author: Manny Rodriguez
#
# --------------------------
# Parses the YAML configuration file, and provides its data as a hash.
# The hash is accessed via the public method values.
#
# SAMPLE USAGE:
#
# config = Configuration.instance
# mets_schema = Configuration.values["mets_schema_location"]
#
# NOTES:
#
# All values are read in from a YAML file hard coded in the CONFIGURATION_FILE constant.

class Configuration

  include Singleton

  attr_reader :values 

  # path to configuration file
  DEFAULT_CONFIGURATION_FILE = File.join(File.dirname(__FILE__), '..', 'etc', 'config.yml')

  def initialize(file=DEFAULT_CONFIGURATION_FILE)
    @values = open(file) { |io| YAML.load io }
  end
  
end
