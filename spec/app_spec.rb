require 'spec_helper'
require 'wip/create'
require File.join(File.dirname(__FILE__), '..', 'app')

describe Validation::App do

  before :each do
    uuid = UUID.generate
    sip = Sip.new File.join(File.dirname(__FILE__), 'sips', 'ateam')
    @wip = Wip.make_from_sip "/tmp/#{ uuid }", "test:/#{uuid}", sip
  end

  it "should detect a good wip" do
    get "/results", "location" => "file:#{@wip.path}"
    last_response.status.should == 200

    get "/results", "location" => "xxx:/#{@wip.path}"
    last_response.status.should == 400

    get "/results", "location" => 'C:\not a uri'
    last_response.status.should == 400
  end

  it "should detect the sip descriptor" do
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'sip descriptor presence', :outcome => 'present')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'success');

    @wip.sip_descriptor['sip-path'] = 'xxx'
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'sip descriptor presence', :outcome => 'missing')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'failure');
  end

  it "should validate the sip descriptor" do
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'sip descriptor validation', :outcome => 'valid')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'success');

    xml = @wip.sip_descriptor.open do |io|
      doc = XML::Document.io io
      doc.find("//@ID").each { |a| a.remove! }
      doc.to_s
    end

    @wip.sip_descriptor.open('w') { |io| io.write xml }

    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'sip descriptor validation', :outcome => 'invalid')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'failure');
  end

  it "should detect at least one data file" do
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'content file presence', :outcome => 'present')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'success');

    FileUtils::rm_r @wip.datafiles.reject { |df| df == @wip.sip_descriptor }.map { |df| File.join @wip.path, 'files', df.id }
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'content file presence', :outcome => 'missing')
    last_response.should have_event(:type => 'comprehensive validation', :outcome => 'failure');
  end

  it "should compare checksums for sip described files" do
    get "/results", "location" => "file:#{@wip.path}"
    last_response.should have_event(:type => 'checksum comparison', :outcome => 'match')
  end

  it "should virus check each file" do
    get "/results", "location" => "file:#{@wip.path}"

    last_response.should have_event(:type => 'virus check', :outcome => 'passed')
  end

end
