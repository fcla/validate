require 'wip'
require 'jxmlvalidation'
require 'libxml'
require 'xmlns'

include LibXML

class Wip

  # Returns the datafile that described the SIP
  def sip_descriptor

    if @cached_sip_descriptor
      @cached_sip_descriptor
    else
      descriptor_name = "#{metadata['sip-name']}.xml"
      @cached_sip_descriptor = datafiles.find { |df| df['sip-path'] ==  descriptor_name }
    end

  end

  # Returns a list of datafiles that are not the descriptor
  def content_files
    datafiles.reject { |df| sip_descriptor == df }
  end

  # Returns an array of datafiles that are described in the sip_descriptor
  def described_datafiles
    if sip_descriptor
      doc = sip_descriptor.open { |io| XML::Document.io io }
      sip_paths = doc.find("//M:file/M:FLocat/@xlink:href", NS_PREFIX).map { |node| node.value }
      datafiles.select { |df| sip_paths.include? df['sip-path'] }
    else
      []
    end
  end

  # Returns true if the sip descriptor is valid, false otherwise. errors are aggregated into sip_descriptor_errors
  def sip_descriptor_valid?
    @sip_descriptor_errors = sip_descriptor.open { |io| JValidation.new(io.read).results }
    @sip_descriptor_errors.empty?
  end
  attr_accessor :sip_descriptor_errors

end
