require 'wip'
require 'jxmlvalidation'
require 'libxml'
require 'xmlns'

include LibXML

class Wip

  def sip_descriptor_name
    @cache_sip_descriptor_name ||= "#{metadata['sip-name']}.xml"
  end

  # Returns the datafile that described the SIP
  def sip_descriptor
    @cache_sip_descriptor ||= datafiles.find { |df| df['sip-path'] ==  sip_descriptor_name }
  end

  def sip_descriptor_doc
    @cache_sip_descriptor_doc ||= sip_descriptor.open { |io| XML::Document.io io }
  end

  def sip_descriptor_checksum df
    file_node = sip_descriptor_doc.find_first "//M:file[M:FLocat/@xlink:href = '#{df.metadata['sip-path']}']", NS_PREFIX

    if file_node
      { :value => file_node['CHECKSUM'], :type => file_node["CHECKSUMTYPE"] }
    end

  end

  # Returns a list of datafiles that are not the descriptor
  def content_files
    datafiles.reject { |df| sip_descriptor == df }
  end

  # Returns an array of datafiles that are described in the sip_descriptor
  def described_datafiles
    if sip_descriptor
      doc = sip_descriptor_doc
      sip_paths = doc.find("//M:file/M:FLocat/@xlink:href", NS_PREFIX).map { |node| node.value }
      datafiles.select { |df| sip_paths.include? df['sip-path'] }
    else
      []
    end
  end

  def validate_sip_descriptor
    val = sip_descriptor.open { |io| JValidation.new io.read }
    @sip_descriptor_errors = val.results
  end

  # Returns true if the sip descriptor is valid, false otherwise. errors are aggregated into sip_descriptor_errors
  def sip_descriptor_valid?
    validate_sip_descriptor unless @sip_descriptor_errors
    @sip_descriptor_errors.empty?
  end
  attr_accessor :sip_descriptor_errors

end
