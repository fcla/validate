require 'libxml'
require 'pp'
require 'namespace'

include LibXML

# Class ExternalProvenanceExtractor
# Author: Manny Rodriguez
#
# --------------------------
# The ExternalProvenanceExtractor class extracts external events and agents from a SIP descriptor, and returns
# a hash of libxml node objects containing them. Expects a path to an AIP. The SIP inside the AIP is presumed to be valid: nil is returned if there are any errors extracting provenance from the AIP.
#
# Returns an hash containing the external events and agents.
# Hash structure:
# hash["agents"] = array of libxml node objects representing external agents
# hash["events"] = array of libxml node objects representing external events
#
# SAMPLE USAGE:
#
# extractor = ExternalProvenanceExtractor.new
# results = extractor.extract_provenance /path/to/aip

# TODO: extracted provenance should be compared to the AIP, so duplicates are removed
class ExternalProvenanceExtractor

  def initalize
    # tell the LibXML parser to ignore whitespace
    XML.default_keep_blanks = false
  end

  def extract_provenance path_to_package

      document = begin 
        get_descriptor_document path_to_package
      rescue => e
        return nil
      end
      
      result = {}
      result["events"] = []
      result["agents"] = []

      event_nodes = get_external_event_nodes document

      event_nodes.each do |node|
        result["events"].push node
      end

      agent_nodes = get_external_agent_nodes document

      agent_nodes.each do |node|
        result["agents"].push node
      end

      return result
    
  end

  def extract_rxp_provenance path_to_package

      document = begin 
        get_descriptor_document path_to_package
      rescue => e
        return nil
      end
      
      rxp_node = get_external_rxp_node document

      return rxp_node
  end

  private

  # returns an LibXML document object representing the package descriptor
  def get_descriptor_document path_to_package
    aip_desc_path = File.join path_to_package, 'descriptor.xml'
    raise "aip descriptor not found" unless File.exist? aip_desc_path
    aip_desc = XML::Parser.file(aip_desc_path).parse
    package_name = aip_desc.root['OBJID']

    sip_desc_path = File.join path_to_package, "files", "#{package_name}.xml"
    raise "sip descriptor not found" unless File.exist? sip_desc_path

    XML::Parser.file(sip_desc_path).parse
  end

  # returns the result of Xpath query for external event nodes
  def get_external_event_nodes document
    document.find('//METS:digiprovMD//premis:event', NS_MAP)
  end

  # returns the result of Xpath query for external agent nodes
  def get_external_agent_nodes document
    document.find('//METS:digiprovMD//premis:agent', NS_MAP)
  end

  # returns the result of Xpath query for external RXP nodes
  def get_external_rxp_node document
    document.find_first("//METS:mdWrap[@LABEL='RXP']//premis:premis", NS_MAP)
  end
  
  def get_sip_name
  end
  
end
