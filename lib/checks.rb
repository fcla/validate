require 'datafile'
require 'libxml'
require 'digest/sha1'
require 'digest/md5'
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

class DataFile

  def compare_checksum?
    raise "#{self} is undescribed" unless wip.described_datafiles.include? self
    doc = wip.sip_descriptor.open { |io| XML::Document.io io }
    file_node = doc.find_first("//mets:file[mets:FLocat/@xlink:href = '#{metadata["sip-path"]}']", 
                               "mets" => "http://www.loc.gov/METS/", 
                               "xlink" => "http://www.w3.org/1999/xlink")

    file_node['CHECKSUM'] == open do |io| 
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

  end

end

module Validation

  module Checks

    def syntax_ok?
      # don't worry about descriptor because wip will take care of that

      # checks that a descriptor of form PACKAGE_NAME.xml/XML exists
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that descriptor is a file
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that at least one content file is present in the package
      # on success, adds appropriate values to hash
      # on failure, adds appropriate values to hash and raises exception

      # checks that the specified account/project in the package is valid
      # TODO: implement
    end

    def account
      # extract the account and return it
    end

    def sip_descriptor_ok?
      # validates package descriptor with external Java validator.
      # if descriptor fails validation, exception is raised and processing stops.
      # Any errors arising from validation will be recorded in @result
    end

    def undescribed_files
      # TODO build a list of files that do not exist in the sip descriptor
    end

    def virus_check_results
      # maybe instead of messing with bin/true we make a VC interface and let whoever implement it
    end

    def checksum_check
      # files.each do ||
      # checks content file checksums against descriptor specified checksum values
      # returns true if all match, false otherwise
      # TODO: check CHECKSUMTYPE attribute, and calcuate accordingly
    end

  end

end
