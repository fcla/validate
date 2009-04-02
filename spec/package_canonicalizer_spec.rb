require 'package_canonicalizer'
require 'pp'

describe PackageCanonicalizer do

  before(:each) do
    @canonicalizer = PackageCanonicalizer.new

    File.stub!(:exists?).and_return true
    File.stub!(:file?).and_return true
    File.stub!(:directory?).and_return true
    File.stub!(:writable?).and_return true
    File.stub!(:readable?).and_return true

    Executor.stub!(:execute_expect_zero).and_return "Sample STDOUT output"
  end
  
  it "unwrap package should raise CanonicalizationParameterError exception if file to unwrap does not exist" do
    File.stub!(:exists?).and_return false

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap package should raise CanonicalizationParameterError exception if file to unwrap is not readable" do
    File.stub!(:readable?).and_return false

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap package should raise CanonicalizationParameterError exception if destination directory does not exist" do
    File.stub!(:exists?).and_return true, false

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap package should raise CanonicalizationParameterError exception if destination directory is a file" do
    File.stub!(:directory?).and_return false

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap package should raise CanonicalizationParameterError exception if destination directory is not writable" do
    File.stub!(:writable?).and_return false

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap_package should raise CanonicalizationParameterError if file to unwrap does not appear as a zip or tar file" do
    lambda { @canonicalizer.unwrap_package "/packages/not_a_wrapped_package", "/unwrap_destination" }.should raise_error(CanonicalizationParameterError)
  end

  it "unwrap_package should correctly identify and process a tar file" do
    @canonicalizer.should_receive(:untar_package)

    lambda { @canonicalizer.unwrap_package "/packages/sample.tar", "/unwrap_destination" }.should_not raise_error
  end

  it "unwrap_package should correctly identify and process a zip file" do
    @canonicalizer.should_receive(:unzip_package)

    lambda { @canonicalizer.unwrap_package "/packages/sample.zip", "/unwrap_destination" }.should_not raise_error
  end
end
