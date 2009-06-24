require 'configuration'
require 'external_provenance_extractor.rb'
require 'pp'

describe ExternalProvenanceExtractor do

  EXTERNAL_PROVENANCE_PRESENT = "spec/SamplePackages/FDA0000012"
  EXTERNAL_PROVENANCE_NOT_PRESENT = "spec/SamplePackages/FDA0000001"
  RXP_PROVENANCE_PRESENT = "spec/SamplePackages/FDA0000014"
  RXP_PROVENANCE_NOT_PRESENT = "spec/SamplePackages/FDA0000012"
  NO_DESCRIPTOR_TO_PARSE = "spec/SamplePackages"

  before(:each) do
    @extractor = ExternalProvenanceExtractor.new
  end

  it "should extract external events from an incoming AIP" do
    result = @extractor.extract_provenance EXTERNAL_PROVENANCE_PRESENT

    result["events"].empty?.should == false
    result["agents"].empty?.should == false

    result["events"].length.should == 2
    result["agents"].length.should == 1
  end


  #TODO: fixme
  it "should return nothing when there are no external events to extract" do
    result = @extractor.extract_provenance EXTERNAL_PROVENANCE_NOT_PRESENT

    result["events"].empty?.should == true
    result["agents"].empty?.should == true
  end

  it "should return nil if descriptor does not exist" do
    result = @extractor.extract_provenance NO_DESCRIPTOR_TO_PARSE
    
    result.should == nil
  end

  it "should return rxp events" do
    result = @extractor.extract_rxp_provenance RXP_PROVENANCE_PRESENT

    result.should_not == nil
  end

  it "should return nil when there are no rxp events present" do
    result = @extractor.extract_rxp_provenance RXP_PROVENANCE_NOT_PRESENT

    result.should == nil
  end
end
