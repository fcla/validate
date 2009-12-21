require 'datafile'
require 'libxml'
require 'digest/sha1'
require 'digest/md5'
require 'xmlns'
require 'jxmlvalidator'

include LibXML

require 'wip/sip_descriptor'
require 'datafile/checksum'
require 'xmlns'

module Validation

  module Checks

    # Returns true if sip descriptor exists and it is not the only file
    def syntax_ok?
      not sip_descriptor.nil? and not (datafiles - sip_descriptor).empty?
    end

    # Returns true if the sip descriptor is valid, false otherwise. errors are aggregated into sip_descriptor_errors
    def sip_descriptor_valid?
      validator = sip_descriptor.open { |io| JValidator.new io.read }
      @sip_descriptor_errors = validator.results
      @sip_descriptor_errors.empty?
    end
    attr_accessor :sip_descriptor_errors

    def account
      doc = sip_descriptor.open { |io| XML::Document.io io }
      name_node = doc.find_first "//M:agent[@ROLE='OTHER' and @OTHERROLE='SUBMITTER']/M:name", NS_PREFIX
      name_node.value
    end

    # Return a list of datafiles that are not described
    def undescribed_files
      datafiles - descriped_datafiles
    end

    # Return a list of datafiles that contain virii
    def virus_check_results

    end

  end

end

class Wip
  include Validation::Checks
end
