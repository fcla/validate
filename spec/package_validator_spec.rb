require 'package_validator'
require 'pp'
require 'executor'
require 'configuration'
require 'digest/md5'

describe PackageValidator do


  # TODO: add checks for path_to_package and described file paths in return hash
  
  ALL_OK_PACKAGE = "spec/SamplePackages/FDA0000001"
  DOES_NOT_EXIST_ON_FILESYSTEM = "foobar"
  NOT_A_DIRECTORY_ON_FILESYSTEM = "Rakefile"
  DOES_NOT_CONTAIN_DESCRIPTOR = "lib"
  DESCRIPTOR_IS_NOT_FILE = "spec/SamplePackages/FDA0000002"
  NO_CONTENT_FILES = "spec/SamplePackages/FDA0000003"
  FILE_REFERENCED_BUT_MISSING = "spec/SamplePackages/FDA0000004"
  CHECKSUM_MISMATCH = "spec/SamplePackages/FDA0000005"
  UNDESCRIBED_FILES_PRESENT = "spec/SamplePackages/FDA0000006"
  NO_DESCRIBED_CHECKSUMS = "spec/SamplePackages/FDA0000007"
  CONTAINS_SUBDIRECTORIES = "spec/SamplePackages/FDA0000008"
  INVALID_DESCRIPTOR = "spec/SamplePackages/FDA0000009"
  NOT_WELL_FORMED_DESCRIPTOR = "spec/SamplePackages/FDA0000010"

  before(:each) do
    @validator = PackageValidator.new
  end
  
  # returns a configuration hash that if used, will simulate a virus found with output on STDOUT and STDERR

  def virus_found_hash
    {"virus_checker_executable" => "echo foo; echo bar 1>&2; /usr/bin/false",
     "virus_exit_status_infected" => 1,
     "virus_exit_status_clean" => 0,
     "xml_validator_executable" => "/Users/manny/workspace/validator/validate 2>&1"}
  end

  it "should validate ALL_OK package, and reflect all checks passed" do
    hash = @validator.validate_package ALL_OK_PACKAGE

    hash["outcome"].should == "success"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["daitss.jpg"]["outcome"].should == "success"
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "success"

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

  it "should fail virus check when virus checker returns an exit status equal to virus_exit_status_infected" do
    Configuration.instance.stub!(:values).and_return virus_found_hash

    hash = @validator.validate_package ALL_OK_PACKAGE

    hash["outcome"].should == "failure"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["daitss.jpg"]["outcome"].should == "failure"
    hash["virus_check"]["daitss.jpg"]["STDOUT"].should == "foo\n"
    hash["virus_check"]["daitss.jpg"]["STDERR"].should == "bar\n"
    hash["virus_check"]["daitss.jpg"]["virus_checker_executable"].should == "echo foo; echo bar 1>&2; /usr/bin/false"

    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "failure"
    hash["virus_check"]["diamondlogo.jpg"]["STDOUT"].should == "foo\n"
    hash["virus_check"]["diamondlogo.jpg"]["STDERR"].should == "bar\n"
    hash["virus_check"]["diamondlogo.jpg"]["virus_checker_executable"].should == "echo foo; echo bar 1>&2; /usr/bin/false"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "success"

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

  it "should fail package syntax check if path provided does not exist on the filesystem" do
    hash = @validator.validate_package DOES_NOT_EXIST_ON_FILESYSTEM

    hash["outcome"].should == "failure"

    # package syntax checks
    
    hash["syntax"]["descriptor_found"].should == nil
    hash["syntax"]["descriptor_is_file"].should == nil
    hash["syntax"]["content_file_found"].should == nil
    hash["syntax"]["package_is_directory"].should == "failure"

    # TODO: account/project verification not yet implemented"

    # descriptor check
    hash["descriptor_validation"].should == nil

    # undescribed file check
    hash["undescribed_files"].should == nil

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should fail package syntax check if path provided does not point to a directory on the filesystem" do
    hash = @validator.validate_package NOT_A_DIRECTORY_ON_FILESYSTEM

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == nil
    hash["syntax"]["descriptor_is_file"].should == nil
    hash["syntax"]["content_file_found"].should == nil
    hash["syntax"]["package_is_directory"].should == "failure"

    # TODO: account/project verification not yet implemented"

    # descriptor check
    hash["descriptor_validation"].should == nil

    # undescribed file check
    hash["undescribed_files"].should == nil

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should fail package syntax check if path provided does not contain a descriptor" do
    hash = @validator.validate_package DOES_NOT_CONTAIN_DESCRIPTOR

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "failure"
    hash["syntax"]["descriptor_is_file"].should == nil
    hash["syntax"]["content_file_found"].should == nil
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor check
    hash["descriptor_validation"].should == nil

    # undescribed file check
    hash["undescribed_files"].should == nil

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should fail package syntax check if path provided contains a descriptor, but that descriptor is not a file" do
    hash = @validator.validate_package DESCRIPTOR_IS_NOT_FILE

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "failure"
    hash["syntax"]["content_file_found"].should == nil
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor check
    hash["descriptor_validation"].should == nil

    # undescribed file check
    hash["undescribed_files"].should == nil

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should fail package syntax check if there are no content files in package" do
    hash = @validator.validate_package NO_CONTENT_FILES

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "failure"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor check
    hash["descriptor_validation"].should == nil

    # undescribed file check
    hash["undescribed_files"].should == nil

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should fail checksum check if there is a file that is referenced, but missing" do
    hash = @validator.validate_package FILE_REFERENCED_BUT_MISSING

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == nil
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "success"

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "failure"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

 it "should fail checksum check if described checksum does not match computed checksum" do
    hash = @validator.validate_package CHECKSUM_MISMATCH

    hash["outcome"].should == "failure"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"

    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "failure"
    hash["checksum_check"]["diamondlogo.jpg"]["described"].should == "8C975DE69A9419B8A02DC985839EA852"
    hash["checksum_check"]["diamondlogo.jpg"]["computed"].should == "8C975DE69A9419B8A02DC985839EA851"

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

 it "should report, and subsequently ignore, undescribed files" do
    hash = @validator.validate_package UNDESCRIBED_FILES_PRESENT

    hash["outcome"].should == "success"

    # package syntax checks

    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 2
    hash["undescribed_files"][0].should == "foo"
    hash["undescribed_files"][1].should == "bar"

    # virus check
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "success"

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
 
    # records for undescribed files foo and bar should not exist
    hash["virus_check"]["foo"].should == nil
    hash["virus_check"]["bar"].should == nil

    hash["checksum_check"]["foo"].should == nil
    hash["checksum_check"]["bar"].should == nil
  end

  it "should validate NO_DESCRIBED_CHECKSUMS package, and reflect all checks passed" do
    hash = @validator.validate_package NO_DESCRIBED_CHECKSUMS

    hash["outcome"].should == "success"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["daitss.jpg"]["outcome"].should == "success"
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["daitss.jpg"]["checksum_match"].should == nil
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == nil

    hash["checksum_check"]["daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

  it "should validate CONTAINS_SUBDIRECTORIES package, and reflect all checks passed" do
    hash = @validator.validate_package CONTAINS_SUBDIRECTORIES

    hash["outcome"].should == "success"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be valid
    hash["descriptor_validation"]["descriptor_valid"].should == "success"

    # undescribed file check
    hash["undescribed_files"].length.should == 0

    # virus check
    hash["virus_check"]["foo/daitss.jpg"]["outcome"].should == "success"
    hash["virus_check"]["diamondlogo.jpg"]["outcome"].should == "success"

    # checksum check
    hash["checksum_check"]["foo/daitss.jpg"]["checksum_match"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["checksum_match"].should == "success"

    hash["checksum_check"]["foo/daitss.jpg"]["file_exists"].should == "success"
    hash["checksum_check"]["diamondlogo.jpg"]["file_exists"].should == "success"
  end

  it "should report an invalid descriptor" do
    hash = @validator.validate_package INVALID_DESCRIPTOR

    hash["outcome"].should == "failure"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be invalid
    hash["descriptor_validation"]["descriptor_valid"].should == "failure"

    # undescribed file check
    hash["undescribed_files"].should == nil 

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end

  it "should report a not well formed descriptor" do
    hash = @validator.validate_package NOT_WELL_FORMED_DESCRIPTOR

    hash["outcome"].should == "failure"

    # package syntax checks
    hash["syntax"]["descriptor_found"].should == "success"
    hash["syntax"]["descriptor_is_file"].should == "success"
    hash["syntax"]["content_file_found"].should == "success"
    hash["syntax"]["package_is_directory"].should == "success"

    # TODO: account/project verification not yet implemented"
    
    # descriptor should be invalid
    hash["descriptor_validation"]["descriptor_valid"].should == "failure"

    # undescribed file check
    hash["undescribed_files"].should == nil 

    # virus check
    hash["virus_check"].should == nil

    # checksum check
    hash["checksum_check"].should == nil
  end
end
