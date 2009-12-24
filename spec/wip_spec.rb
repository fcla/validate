require 'wip/create'
require 'uuid'
require 'wip/sip_descriptor'

describe Wip do

  subject do
    sip = Sip.new File.join(File.dirname(__FILE__), 'sips', 'ateam')
    Wip.make_from_sip "/tmp/#{ UUID.new.generate }", 'test:/', sip
  end

  after :all do
    FileUtils::rm_rf subject.path
  end

  describe "validating the sip descriptor" do

    it "should return true for a valid sip descriptor" do
      subject.sip_descriptor_valid?.should be_true
    end

    it "should return false for an invalid sip descriptor" do
        doc = subject.sip_descriptor.open { |io| XML::Document.io io }
        doc.find("//@ID").each { |attr| attr.remove! }
        subject.sip_descriptor.open("w") { |io| io.write doc.to_s }
        subject.sip_descriptor_valid?.should be_false
    end

  end

end
