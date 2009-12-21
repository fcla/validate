require 'wip'
require 'libxml'
require 'xmlns'

include LibXML

class Wip

  # Returns the datafile that described the SIP
  def sip_descriptor
    datafiles.find { |df| df['sip-path'] == "#{metadata['sip-name']}.xml" } 
  end

  # Returns an array of datafiles that are described in the sip_descriptor
  def described_datafiles
    doc = sip_descriptor.open { |io| XML::Document.io io }
    sip_paths = doc.find("//M:file/M:FLocat/@xlink:href", NS_PREFIX).map { |node| node.value }
    datafiles.select { |df| sip_paths.include? df['sip-path'] }
  end

  # Returns true if the sip descriptor is valid, false otherwise. errors are aggregated into sip_descriptor_errors
  def sip_descriptor_valid?
    validator = sip_descriptor.open { |io| JValidator.new io.read }
    @sip_descriptor_errors = validator.results
    @sip_descriptor_errors.empty?
  end
  attr_accessor :sip_descriptor_errors

  # Return a list of datafiles that are not described
  def undescribed_files
    datafiles - descriped_datafiles
  end

end
