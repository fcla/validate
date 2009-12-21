require 'wip/sip_descriptor'

class Wip

  # Returns the account specified in a sip descriptor
  def account
    doc = sip_descriptor.open { |io| XML::Document.io io }
    node = doc.find_first "//M:agent[@ROLE='OTHER' and @OTHERROLE='SUBMITTER']/M:name", NS_PREFIX
    node ? name_node.value : nil
  end

end
