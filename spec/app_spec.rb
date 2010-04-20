require 'spec_helper'

require File.join(File.dirname(__FILE__), '..', 'app')

describe Validation::App do

  it "should passed clean virus check status for clean file" do
    file_string = StringIO.new

    # read file into string io
    File.open "spec/files/ateam.tiff" do |file|
      file_string << file.read 
    end

    post "/", file_string

    last_response.should have_event(:type => "virus check", :outcome => "passed")
  end

  it "should return failed virus check event for infected file" do
    file_string = StringIO.new

    # read file into string io
    File.open "spec/files/eicar.com" do |file|
      file_string << file.read 
    end

    post "/", file_string

    last_response.should have_event(:type => "virus check", :outcome => "failed")
  end

  it "should return 400 if body is empty" do

    post "/"

    last_response.status.should == 400
  end
end
