require 'digest/md5'
require 'digest/sha1'
require 'xmlns'

class DataFile

  # Returns [sip descriptor checksum, computed checksum]
  def checksum_info
    doc = wip.descriptor_doc
    file_node = doc.find_first "//M:file[M:FLocat/@xlink:href = '#{metadata["sip-path"]}']", NS_PREFIX
    raise "#{self} is undescribed" unless file_node
    expected_md = file_node['CHECKSUM']

    if expected_md

      actual_md = open do |io|

        case file_node["CHECKSUMTYPE"]
        when "MD5" then Digest::MD5.hexdigest io.read
        when "SHA-1" then Digest::SHA1.hexdigest io.read
        when nil then infer expected_md
        else raise "Unsupported checksum type: #{file_node["CHECKSUMTYPE"]}"
        end

      end

      [expected_md, actual_md]
    else
      [nil,nil]
    end

  end

  private

  def infer s

    case s
    when %r{[a-fA-F0-9]{40}} then Digest::MD5.hexdigest io.read
    when %r{[a-fA-F0-9]{32}} then  Digest::SHA1.hexdigest io.read
    else raise "Missing checksum type"
    end

  end

end
