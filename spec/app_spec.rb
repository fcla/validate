require 'spec'
require 'rack/test'
require 'validate_app'
require 'wip/create'
require 'uuid'
require 'xmlns'
require 'jxmlvalidation'

Spec::Runner.configure do |conf|
  conf.include Rack::Test::Methods
end

set :environment, :test

def app
  Validation::App
end

Spec::Matchers.define :have_event do |options|

  match do |res|
    doc = XML::Document.string res.body
    xpath = %Q{//P:event[ P:eventType = '#{options[:type]}' and 
                          P:eventOutcomeInformation/P:eventOutcome = '#{options[:outcome]}' ]} 
    doc.find_first xpath, NS_PREFIX
  end

  failure_message_for_should do |res|
    "expected response to have a premis event: #{options.inspect}"
  end

  failure_message_for_should_not do |res|
    "expected response to not have a premis event: #{options.inspect}"
  end

end

UUID_GENERATOR = UUID.new

describe Validation::App do

  before :each do
    sip = Sip.new File.join(File.dirname(__FILE__), 'sips', 'ateam')
    @wip = Wip.make_from_sip "/tmp/#{ UUID_GENERATOR.generate }", 'test:/', sip
  end

  it "should detect a good wip" do
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.status.should == 200

    get "/results", "location" => URI.join('xxx:/', @wip.path).to_s 
    last_response.status.should == 400
  end

  it "should detect the sip descriptor" do
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'sip descriptor presence', :outcome => 'present')

    @wip.sip_descriptor['sip-path'] = 'xxx'
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'sip descriptor presence', :outcome => 'missing')
  end

  it "should validate the sip descriptor" do
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'sip descriptor validation', :outcome => 'valid')

    xml = @wip.sip_descriptor.open do |io| 
      doc = XML::Document.io io
      doc.find("//@ID").each { |a| a.remove! }
      doc.to_s
    end

    @wip.sip_descriptor.open('w') { |io| io.write xml }

    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'sip descriptor validation', :outcome => 'invalid')
  end

  it "should validate the sip account"
  
  it "should detect at least one data file" do
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'content file presence', :outcome => 'present')

    FileUtils::rm_r @wip.datafiles.reject { |df| df == @wip.sip_descriptor }.map { |df| File.join @wip.path, 'files', df.id }
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'content file presence', :outcome => 'missing')
  end

  it "should compare checksums for sip described files" do
    get "/results", "location" => URI.join('file:/', @wip.path).to_s
    last_response.should have_event(:type => 'checksum comparison', :outcome => 'match')
  end

  it "should virus check each file"
end
