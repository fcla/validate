require 'find'
require 'libxml'
require 'yaml'
require 'pp'
require 'executor'
require 'digest/md5'
require 'configuration'

# Class PackageValidator
# Author: Manny Rodriguez
#
# --------------------------
# The PackageValidator class encapsulates package validation tasks
#
# These tasks include: Validation of package syntax, SIP descriptor validation, File checksum validation, virus check, account/project validation
#
# SAMPLE USAGE:
#
# validator = PackageValidator.new
# validator.validate_package /path/to/package
#
# NOTES:
# If *BOTH* PACKAGE_NAME.xml and PACKAGE_NAME.XML are present, PACKAGE_NAME.XML will be treated as a content file

class ValidationFailed < StandardError; end

class PackageValidator

  def initialize
    @package_paths_array = []
    @descriptor_path = ""
    @descriptor_document
    @report = LibXML::XML::Document.new

    @report.root = LibXML::XML::Node.new 'validity'

    # tell the LibXML parser to ignore whitespace
    LibXML::XML::Parser.default_keep_blanks = false
  end

  # runs all validation tasks on a package, building an XML report as the validation progresses.
  # report is returned after validation completes.
  # if a failure prevents the running of all checks, a report containing all checks performed is returned
  
  def validate_package(path_to_package)
    begin
      validate_package_syntax path_to_package
      validate_descriptor
      validate_account_project
      virus_check_clean = virus_check
      checksums_match = validate_checksums

    # any ValidationFailed exceptions caught indicate a problem with the package 
    rescue ValidationFailed
      @report.root['outcome'] = "failure"

    # any other exceptions caught will result in report indicating failure to complete validation
    #rescue => e
      #@report.root['outcome'] = "validation_failed"
    end

    # no exceptions caught mean no fatal errors, let's see what happened with the virus and checksum checks
    if virus_check_clean && checksums_match
      @report.root['outcome'] = "success"
    else
      @report.root['outcome'] = "failure"
    end

    # return string serialization of validation report
    return @report.to_s
  end

  private 

  # creates a node with given name and outcome value
  
  def create_node node_name, outcome
    node = LibXML::XML::Node.new node_name
    node["outcome"] = outcome

    return node
  end

  # adds current report node to root report node, then throws ValidationFailed exception

  def fail_validation message, node
    @report.root << node
    raise ValidationFailed, message
  end

  # checks that a package is in expected form:
  # * Target path is a directory that exists
  # * A SIP descriptor named DIRECTORY_NAME/DIRECTORY_NAME.xml is present
  # * There is at least one other file in DIRECTORY_NAME
  #
  # if the package validates successfully, class variables @package_paths_array and @descriptor_path are set
  # if package fails validation, exception is raised
  #
  # This method calls 4 other methods that perform the above checks:
  # validate_syntax_path_is_dir
  # validate_syntax_descriptor_exists
  # validate_syntax_descriptor_is_file
  # validate_syntax_content_file_present

  def validate_package_syntax path_to_package
    syntax_report_node = LibXML::XML::Node.new 'package_syntax'

    syntax_report_node = validate_syntax_path_is_dir(path_to_package, syntax_report_node)
    syntax_report_node = validate_syntax_descriptor_exists(path_to_package, syntax_report_node)
    syntax_report_node = validate_syntax_descriptor_is_file(path_to_package, syntax_report_node)
    syntax_report_node = validate_syntax_content_file_present(path_to_package, syntax_report_node)
  
    @report.root << syntax_report_node
  end

  # checks that path to package specified is a directory
  # takes a node syntax_report_node, and path to package
  # on success, writes child element to and returns syntax_report_node
  # on failure, calls fail_validation, passing syntax_report_node after writing child element with failure details

  def validate_syntax_path_is_dir path_to_package, syntax_report_node
    if not File.directory? path_to_package
      syntax_report_node << create_node("package_is_directory", "failure")
      fail_validation "Specified path is not a directory", syntax_report_node
    else
      syntax_report_node << create_node("package_is_directory", "success")
    end

    return syntax_report_node
  end

  # checks that a descriptor of form PACKAGE_NAME.xml/XML exists
  # takes a node syntax_report_node, and path to package
  # on success, writes child element to and returns syntax_report_node
  # on failure, calls fail_validation, passing syntax_report_node after writing child element with failure details

  def validate_syntax_descriptor_exists path_to_package, syntax_report_node
    # get a list of the files therein and put it into an array
    Find.find(path_to_package) do |stuff|
      @package_paths_array.push stuff
    end

    package_basename = File.basename @package_paths_array[0]

    # the value at index 0 is always the directory name, so we look for a file named package_file_array[0].xml
    if @package_paths_array.include? "#{@package_paths_array[0]}/#{package_basename}.xml"
      @descriptor_path = "#{@package_paths_array[0]}/#{package_basename}.xml"
      syntax_report_node << create_node("descriptor_found", "success")

      # if we didn't find PACKAGE_NAME.xml, there is still the possibility we have PACAKGE_NAME.XML
    elsif @package_paths_array.include? "#{@package_paths_array[0]}/#{package_basename}.XML"
      @descriptor_path = "#{@package_paths_array[0]}/#{package_basename}.XML"
      syntax_report_node << create_node("descriptor_found", "success")

    else
      syntax_report_node << create_node("descriptor_found", "failure")
      fail_validation "Expected SIP descriptor not found", syntax_report_node
    end

    return syntax_report_node
  end

  # checks that descriptor is a file
  # takes a node syntax_report_node, and path to package
  # on success, writes child element to and returns syntax_report_node
  # on failure, calls fail_validation, passing syntax_report_node after writing child element with failure details

  def validate_syntax_descriptor_is_file path_to_package, syntax_report_node
    if File.file? @descriptor_path
      syntax_report_node << create_node("descriptor_is_file", "success")
    else
      syntax_report_node << create_node("descriptor_is_file", "failure")
      fail_validation "SIP descriptor is not a file", syntax_report_node
    end

    return syntax_report_node
  end

  # checks that at least one content file is present in the package
  # takes a node syntax_report_node, and path to package
  # on success, writes child element to and returns syntax_report_node
  # on failure, calls fail_validation, passing syntax_report_node after writing child element with failure details

  def validate_syntax_content_file_present path_to_package, syntax_report_node
    content_file_found = false

    @package_paths_array.each do |path|
      next if path == @descriptor_path
      content_file_found = true if File.file? path
      break if content_file_found == true
    end

    if content_file_found
      syntax_report_node << create_node("content_file_found", "success")
    else
      syntax_report_node << create_node("content_file_found", "failure")
      fail_validation "No content files found", syntax_report_node
    end

    return syntax_report_node
  end


  # checks that the specified account/project in the package is valid
  # TODO: implement

  def validate_account_project 
    ap_report_node = LibXML::XML::Node.new 'account_project_validation'

    ap_report_node << create_node("account_project_valid", "test_not_implemented")

    @report.root << ap_report_node
  end

  # passes descriptor to XML validation service
  # TODO: implement, once we have an XML validation service
  def validate_descriptor
    descriptor_validation_node = LibXML::XML::Node.new 'descriptor_validation'
    descriptor_validation_node << create_node("descriptor_valid", "test_not_implemented")
    @report.root << descriptor_validation_node

    # for now, we have to assume the descriptor is valid
    @descriptor_document = LibXML::XML::Document.file @descriptor_path

    # code below was a simple LibXML validator, used before we decided to break XML validation out into it's own service
    
    #begin
      ## tell the parser to ignore whitespace
      #LibXML::XML::Parser.default_keep_blanks = false
#
      #mets_schema = LibXML::XML::Schema.new Configuration.instance.mets_schema_location
#
      #@descriptor_document = LibXML::XML::Document.file @descriptor_path
      #root_node = @descriptor_document.root
      #children = root_node.children
#
      ## we expect that our root node is in the METS namespace
      #raise ValidationFailed, "Root node not in METS namespace" unless root_node.namespace_node.prefix == "METS"
#
      ## validate the document against METS schema
      #raise ValidationFailed, "Descriptor did not validate against the METS schema" unless @descriptor_document.validate_schema mets_schema
#
      ## get the account/project, then set instance variables accordingly
      #agreement_info_node = @descriptor_document.find_first('//daitss:AGREEMENT_INFO')
#
      #raise ValidationFailed, "Agreement info missing" unless agreement_info_node
#
      #agreement_info_attributes = agreement_info_node.attributes
#
      #@account = agreement_info_attributes["ACCOUNT"]
      #@project = agreement_info_attributes["PROJECT"]
#
    #rescue LibXML::XML::Parser::ParseError 
      #raise ValidationFailed, "Error parsing XML file, please check for well-formedness"
    #end
  end

  # runs a virus check on the package
  # Iterates over all files in package, calling Configuration.virus_checker_executable for each one
  # returns true if all clean, false otherwise
  
  def virus_check
    virus_check_node = LibXML::XML::Node.new 'virus_check'
    all_ok = true

    @package_paths_array.each do |path|
      if File.file? path
        summary = Executor.execute_return_summary "#{Configuration.instance.virus_checker_executable} #{path}"

        # inspect the exit status of the virus checker to see what the result is for this file

        case summary["exit_status"]

          # success
        when Configuration.instance.virus_exit_status_clean
          node = create_node("virus_check_file", "passed")
          node["path"] = path
          node["virus_checker_executable"] = Configuration.instance.virus_checker_executable

          virus_check_node << node

          # virus found
        when Configuration.instance.virus_exit_status_infected
          node = create_node("virus_check_file", "failed")
          node["path"] = path
          node["virus_checker_executable"] = Configuration.instance.virus_checker_executable

          if summary['STDOUT'] != nil
            stdout_node = LibXML::XML::Node.new 'STDOUT'
            stdout_node << summary['STDOUT']
          else
            stdout_node = LibXML::XML::Node.new 'STDOUT'
          end

          if summary['STDERR'] != nil
            stderr_node = LibXML::XML::Node.new 'STDERR'
            stderr_node << summary['STDERR']
          else
            stderr_node = LibXML::XML::Node.new 'STDERR'
          end

          node << stdout_node
          node << stderr_node
          virus_check_node << node
          all_ok = false

          # non-zero exit status that is not the success case
        else
          node = create_node("virus_check_file", "indeterminate")
          node["path"] = path
          node["virus_checker_executable"] = Configuration.instance.virus_checker_executable

          if summary['STDOUT'] != nil
            stdout_node = LibXML::XML::Node.new 'STDOUT'
            stdout_node << summary['STDOUT']
          else
            stdout_node = LibXML::XML::Node.new 'STDOUT'
          end

          if summary['STDERR'] != nil
            stderr_node = LibXML::XML::Node.new 'STDERR'
            stderr_node << summary['STDERR']
          else
            stderr_node = LibXML::XML::Node.new 'STDERR'
          end

          node << stdout_node
          node << stderr_node
          virus_check_node << node
          all_ok = false

        end
      end # of if
    end # of loop

    @report.root << virus_check_node
    return all_ok
  end # of method virus_check

  # checks content file checksums against descriptor specified checksum values
  # returns true if all match, false otherwise
  # TODO: check CHECKSUMTYPE attribute, and calcuate accordingly
  
  def validate_checksums
    checksum_node = LibXML::XML::Node.new 'checksum_check'
    all_ok = true

    file_nodes = @descriptor_document.find('//METS:file').to_a

    # iterate through all the file nodes, ensuring that all described files are present, and checksums match (if provided in descriptor)
    file_nodes.each do |file_node|
      file_node_attributes = file_node.attributes

      flocat_node = file_node.child
      flocat_node_attributes = flocat_node.attributes

      file_path = File.join @package_paths_array[0], flocat_node_attributes["href"]
      described_checksum = file_node_attributes["CHECKSUM"]

      # check to see that the file exists, report accordingly
      if File.exists? file_path
        fe_node = create_node("file_exists", "success")
        fe_node['path'] = file_path
        checksum_node << fe_node
      else
        fe_node = create_node("file_exists", "faliure")
        fe_node['path'] = file_path
        checksum_node << fe_node

        all_ok = false
      end

      # if a described checksum is present in descriptor, compute the checksum for the file.
      # Otherwise, set variable computed_checksum == described_checksum == nil so that equality test in next statement passes
      if described_checksum
        computed_checksum = compute_file_checksum file_path
      else
        computed_checksum = described_checksum
      end

      if computed_checksum.upcase == described_checksum.upcase
        cm_node = create_node("checksum_match", "success")
        cm_node['path'] = file_path
        checksum_node << cm_node
      else
        cm_node = create_node("checksum_match", "failure")
        cm_node['path'] = file_path
        cm_node['described'] = described_checksum.upcase
        cm_node['computed'] = computed_checksum.upcase

        checksum_node << cm_node

        all_ok = false
      end

    end # of loop
    @report.root << checksum_node
    return all_ok
  end

  # returns the MD5 checksum of file. Raises exception if checksum cannot be calculated
  
  def compute_file_checksum path_to_file
    raise StandardError, "File at path does not exist" unless File.exists? path_to_file
    raise StandardError, "Path provided does not refer to a file" unless File.file? path_to_file
    raise StandardError, "File is not readable" unless File.readable? path_to_file

    #TODO: we may want to calculate the MD5 hashes in chunks
    Digest::MD5.hexdigest(File.read(path_to_file))
  end
end
