require 'wip/create'
require 'datafile/checksum'
require 'datafile/virus'
require 'xmlns'
require 'uuid'
require 'wip/sip_descriptor'
require 'daitss/config'

describe DataFile do

  subject do
    sip = Sip.new File.join(File.dirname(__FILE__), 'sips', 'ateam')
    @wip = Wip.make_from_sip "/tmp/#{ UUID.generate }", 'test:/', sip
    @wip.described_datafiles.first
  end

  after(:all) { FileUtils::rm_rf @wip.path }

  describe "checksum info" do

    it "should have sip descriptor checksum match the computed checksum" do
      des, comp = subject.checksum_info
      des.should == comp
    end

    it "should be false for files when something is wrong" do
      subject.open("a") { |io| io.puts "oops" }
      des, comp = subject.checksum_info
      des.should_not == comp
    end

    it "should raise an error if the checksum type is unsupported" do
      doc = subject.wip.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file[M:FLocat/@xlink:href = '#{subject['sip-path']}']/@CHECKSUMTYPE", NS_PREFIX).each { |node| node.value = "SHA-2" }
      subject.wip.sip_descriptor.open("w") { |io| io.write doc.to_s }

      lambda {
        fresh_wip = Wip.new subject.wip.path
        fresh_wip.datafiles.first.checksum_info
      }.should raise_error("Unsupported checksum type: SHA-2")
    end

    it "should raise an error if the checksum type is missing and cannot infer SHA-1 or MD5" do
      doc = subject.wip.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file[M:FLocat/@xlink:href = '#{subject['sip-path']}']/@CHECKSUMTYPE", NS_PREFIX).each { |node| node.remove! }
      doc.find("//M:file[M:FLocat/@xlink:href = '#{subject['sip-path']}']/@CHECKSUM", NS_PREFIX).each { |node| node.value = "xxx" }
      subject.wip.sip_descriptor.open("w") { |io| io.write doc.to_s }

      lambda {
        fresh_wip = Wip.new subject.wip.path
        fresh_wip.datafiles.first.checksum_info
      }.should raise_error("Missing checksum type")
    end

    it "should infer SHA-1 or MD5 by length and contents for checksum type if missing" do
      doc = subject.wip.sip_descriptor.open { |io| XML::Document.io io }
      doc.find("//M:file[M:FLocat/@xlink:href = '#{subject['sip-path']}']/@CHECKSUMTYPE", NS_PREFIX).each { |node| node.remove! }
      subject.wip.sip_descriptor.open("w") { |io| io.write doc.to_s }

      lambda { subject.df.checksum_info }.should_not raise_error("Missing checksum type")
    end

    it "should virus check itself" do
      subject.virus_check.should == true
    end

    it "should raise error if virus is found" do
      Daitss::CONFIG.stub!(:[]).and_return "false"
      
      lambda { subject.virus_check }.should raise_error(VirusFound)
    end
  end
end

