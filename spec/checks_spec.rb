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
      subject.datafiles.each { |f| f.compare_checksum?.should be_true }
    end

    it "should be false for files when something is wrong" do
      subject.datafiles.first.open("a") { |io| io.puts "oops" }
      subject.datafiles.first.compare_checksum?.should be_false
    end

    it "should return nil/raise exception for files that are undescribed" do
      df = subject.new_datafile
      df.open("a") { |io| io.puts "oops" }
      subject.datafiles.last.compare_checksum?.should be_nil
    end
    # make sure false and nil are mot mixed
  end
  
end
