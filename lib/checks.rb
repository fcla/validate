require 'datafile'

class DataFile

  def compare_checksum?
    descriptor = wip.datafiles.find { |df| "#{df['sip-path']}.xml" == wip['sip-name'] }
  end

end

module Validation

  module Checks

    def syntax_ok?
      # don't worry about descriptor because wip will take care of that

      # checks that a descriptor of form PACKAGE_NAME.xml/XML exists
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that descriptor is a file
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that at least one content file is present in the package
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that the specified account/project in the package is valid
      # TODO: implement
    end

    def account
      # extract the account and return it
    end

    def sip_descriptor_ok?
      # validates package descriptor with external Java validator.
      # if descriptor fails validation, exception is raised and processing stops.
      # Any errors arising from validation will be recorded in @result
    end

    def undescribed_files
      # TODO build a list of files that do not exist in the sip descriptor
    end

    def virus_check_results
      # maybe instead of messing with bin/true we make a VC interface and let whoever implement it
    end

    def checksum_check
      # files.each do ||
      # checks content file checksums against descriptor specified checksum values
      # returns true if all match, false otherwise
      # TODO: check CHECKSUMTYPE attribute, and calcuate accordingly
    end

  end

end
