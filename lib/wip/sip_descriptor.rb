require 'wip'
require 'libxml'
require 'xmlns'

include LibXML

class Wip

  def sip_descriptor
    datafiles.find { |df| df['sip-path'] == "#{metadata['sip-name']}.xml" } 
  end


  def described_datafiles
    doc = sip_descriptor.open { |io| XML::Document.io io }
    sip_paths = doc.find("//M:file/M:FLocat/@xlink:href", NS_PREFIX).map { |node| node.value }
    datafiles.select { |df| sip_paths.include? df['sip-path'] }
  end

end
