require 'checks'
require 'wip/create'
require 'uuid'

describe Validation::Checks do

  subject do
    sip = Sip.new File.join(File.dirname(__FILE__), 'sips', 'ateam')
    Wip.make_from_sip "/tmp/#{ UUID.new.generate }", 'test:/', sip
  end

  after :all do
    FileUtils::rm_rf subject.path
  end

  describe "checksum comparison" do

    it "should be true for all files when everything is good" do
      subject.described_datafiles.each { |f| f.compare_checksum?.should be_true }
    end

    it "should be false for files when something is wrong" do
      subject.described_datafiles.first.open("a") { |io| io.puts "oops" }
      subject.described_datafiles.first.compare_checksum?.should be_false
    end

    it "should raise error for files that are undescribed" do
      df = subject.new_datafile
      lambda { df.compare_checksum? }.should raise_error("#{df} is undescribed")
    end

    it "should raise an error if the checksum type is unsupported" do
      doc = subject.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file/@CHECKSUMTYPE", "M" => "http://www.loc.gov/METS/").each { |node| node.value = "SHA-2" }
      subject.sip_descriptor.open("w") { |io| io.write doc.to_s }

      lambda { subject.described_datafiles.each { |df| df.compare_checksum? } }.should raise_error("Unsupported checksum type: SHA-2")
    end

    it "should raise an error if the checksum type is missing and cannot infer SHA-1 or MD5" do
      doc = subject.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file/@CHECKSUMTYPE", "M" => "http://www.loc.gov/METS/").each { |node| node.remove! }
      doc.find("//M:file/@CHECKSUM", "M" => "http://www.loc.gov/METS/").each { |node| node.value = "xxx" }
      subject.sip_descriptor.open("w") { |io| io.write doc.to_s }

      lambda { subject.described_datafiles.each { |df| df.compare_checksum? } }.should raise_error("Missing checksum type")
    end

    it "should infer SHA-1 or MD5 by length and contents for checksum type if missing" do
      doc = subject.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file/@CHECKSUMTYPE", "M" => "http://www.loc.gov/METS/").each { |node| node.remove! }
      subject.sip_descriptor.open("w") { |io| io.write doc.to_s }
      
      subject.described_datafiles.each { |df| df.compare_checksum? }.should_not raise_error("Missing checksum type")
    end


  end
  
end
