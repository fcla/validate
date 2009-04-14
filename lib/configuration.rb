require 'yaml'
require 'singleton'

# Class Configuration
# Author: Manny Rodriguez
#
# --------------------------
# The Configuration class encapsulates configuration variable aggregation. It reads in the main configuration
# YAML file and provides getter methods to the values defined inside.
#
# SAMPLE USAGE:
#
# config = Configuration.instance
# mets_schema = Configuration.mets_schema_location
#
# NOTES:
#
# All values are read in from a YAML file hard coded in the CONFIGURATION_FILE constant.

class Configuration

  include Singleton

  # path to configuration file
  CONFIGURATION_FILE = "/Users/manny/workspace/validate-service/etc/config.yml"

  attr_reader :virus_exit_status_infected
  attr_reader :virus_exit_status_clean
  attr_reader :virus_checker_executable
  attr_reader :unzip_executable_path
  attr_reader :tar_executable_path

  attr_reader :mets_schema_location

  attr_reader :temp_dir

  def initialize
    config_values = YAML.load(open(CONFIGURATION_FILE))

    @virus_exit_status_infected = config_values["virus_exit_status_infected"]
    @virus_exit_status_clean = config_values["virus_exit_status_clean"]
    @virus_checker_executable = config_values["virus_checker_executable"]
    @tar_executable_path = config_values["tar_executable_path"]
    @unzip_executable_path = config_values["unzip_executable_path"]

    # schema locations
    
    @mets_schema_location = config_values["METS"]

    # temporary directory for validation

    @temp_dir = config_values["temp_dir"]
  end
end
