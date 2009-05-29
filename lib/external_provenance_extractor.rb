require 'libxml'
require 'pp'

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
    LibXML::XML.default_keep_blanks = false
  end

  def extract_provenance path_to_package
    begin
      document = get_descriptor_document path_to_package
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
    rescue => e
      return nil
    end
  end

  private

  # returns an LibXML document object representing the package descriptor

  def get_descriptor_document path_to_package
      package_name = File.basename path_to_package

      if File.exists?(File.join(path_to_package, "files", "#{package_name}.xml"))
        document = LibXML::XML::Document.file(File.join(path_to_package, "files", "#{package_name}.xml"))

      elsif File.exists?(File.join(path_to_package, "files", "#{package_name}.XML"))
        document = LibXML::XML::Document.file(File.join(path_to_package, "files", "#{package_name}.XML"))
      else
        raise StandardError, "Descriptor not found"
      end

      return document
  end

  # returns the result of Xpath query for external event nodes

  def get_external_event_nodes document
    begin
      return document.find('//METS:digiprovMD//premis:event')
    rescue => e
      return Array.new
    end
  end

  # returns the result of Xpath query for external agent nodes
  def get_external_agent_nodes document
    begin
      return document.find('//METS:digiprovMD//premis:agent',
                           'METS' => 'http://www.loc.gov/METS/',
                           'premis' => 'info:lc/xmlns/premis-v2')
    rescue => e
      return Array.new
    end
  end
end
