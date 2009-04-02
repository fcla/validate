require 'package_validator'
require 'pp'
require 'libxml'
require 'executor'
require 'configuration'
require 'digest/md5'

describe PackageValidator do

  before(:each) do
    @validator = PackageValidator.new

    # stubs for File methods
    File.stub!(:exists?).and_return true
    File.stub!(:file?).and_return true
    File.stub!(:directory?).and_return true
    File.stub!(:writable?).and_return true
    File.stub!(:readable?).and_return true
    File.stub!(:read).and_return ""

    # stubs for Configuration
    Configuration.stub!(:virus_checker_executable).and_return "/bin/true"
    Configuration.stub!(:virus_exit_status_clean).and_return 0
    Configuration.stub!(:virus_exit_status_infected).and_return 1

    # mock filesystem 
    mock_paths = "/path/to/package/package_name", 
                 "/path/to/package/package_name/content_file.tif",
                 "/path/to/package/package_name/package_name.xml"

    # mock account info
    account_info = {"ACCOUNT"=>"FDA", "PROJECT"=>"FDA"}

    # mock file info
    file_info = {"CHECKSUM" => "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "href" => "content_file.tif"}

    # mock exit status array
    stub_return_status = {"exit_status" => 0, "STDOUT" => "", "STDERR" => ""}

    # stub Find.find, to mock directory traversal
    Find.stub!(:find).and_yield(mock_paths[0]).and_yield(mock_paths[1]).and_yield(mock_paths[2])

    # stub Executor.execute_return_summary
    Executor.stub!(:execute_return_summary).and_return stub_return_status

    # mock XML objects, documents and nodes
    @mock_doc = mock 'mock XML document' 
    @mock_node = mock 'mock XML node'
    @mock_namespace_node = mock 'mock XML namespace node'
    @mock_file_node = mock 'mock METS filesec node'

    @mock_doc.stub!(:root).and_return @mock_node
    @mock_doc.stub!(:find).and_return [@mock_file_node]
    @mock_doc.stub!(:find_first).and_return @mock_node
    @mock_doc.stub!(:validate_schema).and_return true

    @mock_node.stub!(:children).and_return true
    @mock_node.stub!(:namespace_node).and_return @mock_namespace_node
    @mock_node.stub!(:attributes).and_return account_info

    @mock_file_node.stub!(:attributes).and_return file_info
    @mock_file_node.stub!(:child).and_return @mock_file_node

    @mock_namespace_node.stub!(:prefix).and_return "METS" 

    # stub LibXML methods
    LibXML::XML::Schema.stub!(:new).and_return true
    LibXML::XML::Document.stub!(:file).and_return @mock_doc
     
    # stub Digest::MD5 methods
    Digest::MD5.stub!(:hexdigest).and_return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end
  
  it "validate_pacakge should raise ValidationFailedSyntax if specified package path is not a directory" do
    File.stub!(:directory?).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedSyntax)
  end

  it "validate_pacakge should raise ValidationFailedSyntax if specified package path is not readable" do
    File.stub!(:readable?).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedSyntax)
  end

  it "validate_pacakge should raise ValidationFailedSyntax if package_name{xml,XML} not present" do
    mock_paths = "/path/to/package/package_name", "/path/to/package/package_name/content_file.tif"
    Find.stub!(:find).and_yield(mock_paths[0]).and_yield(mock_paths[1])

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedSyntax)
  end

  it "validate_pacakge should raise ValidationFailedSyntax if SIP descriptor is not a file" do
    File.stub!(:file?).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedSyntax)
  end

  it "validate_pacakge should raise ValidationFailedSyntax if there are no content files" do
    File.stub!(:file?).and_return true, false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedSyntax)
  end

  it "validate_package should raise ValidationFailedAccountProject if account/project are invalid" do
    pending "need to implement account project check"
  end

  it "validate_package should succesfully check account/project if account/project are valid" do
    pending "need to implement account project check"
  end

  it "validate_package should raise ValidationFailedDescriptor if root node is not in METS namespace" do
    @mock_namespace_node.stub!(:prefix).and_return "FOO" 

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedDescriptor)
  end

  it "validate_package should raise ValidationFailedDescriptor if descriptor does not validate against METS schema" do
    @mock_doc.stub!(:validate_schema).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedDescriptor)
  end

  it "validate_package should raise ValidationFailedDescriptor if agreement info is missing from descriptor" do
    @mock_doc.stub!(:find_first).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedDescriptor)
  end

  it "validate_package should raise ValidationFailedDescriptor if descriptor is not well-formed" do
    LibXML::XML::Document.stub!(:file).and_raise LibXML::XML::Parser::ParseError

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedDescriptor)
  end
  
  it "validate_package should raise ValidationFailedVirusCheck if virus found" do
    stub_return_status = {"exit_status" => 1, "STDOUT" => "", "STDERR" => ""}
    Executor.stub!(:execute_return_summary).and_return stub_return_status

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedVirusCheck)
  end

  it "validate_package should raise ValidationFailedVirusCheck if virus checker exit status is indeterminate" do
    stub_return_status = {"exit_status" => 3, "STDOUT" => "", "STDERR" => ""}
    Executor.stub!(:execute_return_summary).and_return stub_return_status

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedVirusCheck)
  end

  it "validate_package should raise ValidationFailedChecksum if a file is described but not present in package" do
    File.stub!(:exists?).and_return false

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedChecksum) 
  end

  it "validate_package should raise ValidationFailedChecksum if there is a checksum mismatch" do
    Digest::MD5.stub!(:hexdigest).and_return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab"

    lambda { @validator.validate_package "/path_to_package/UF000001" }.should raise_error(ValidationFailedChecksum) 
  end

  it "validate_package should return true, and not raise exception any errors is package is valid" do
    lambda { @valid = @validator.validate_package "/path_to_package/UF000001" }.should_not raise_error
    @valid.should == true
  end
end
