require 'xmlns'

class DataFile

  # returns [sip descriptor checksum, computed checksum]
  def checksum_info
    raise "#{self} is undescribed" unless wip.described_datafiles.include? self
    doc = wip.sip_descriptor.open { |io| XML::Document.io io }
    file_node = doc.find_first "//M:file[M:FLocat/@xlink:href = '#{metadata["sip-path"]}']", NS_PREFIX 
    expected_md = file_node['CHECKSUM']

    actual_md = open do |io| 
      case file_node["CHECKSUMTYPE"]
      when "MD5" then Digest::MD5.hexdigest io.read
      when "SHA-1" then Digest::SHA1.hexdigest io.read
      when nil

        case file_node["CHECKSUM"]
        when %r{[a-fA-F0-9]{40}} then Digest::MD5.hexdigest io.read
        when %r{[a-fA-F0-9]{32}} then  Digest::SHA1.hexdigest io.read
        else raise "Missing checksum type"
        end

      else raise "Unsupported checksum type: #{file_node["CHECKSUMTYPE"]}"
      end
    end

    [expected_md, actual_md]
  end

end
