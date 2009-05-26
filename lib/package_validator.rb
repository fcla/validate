require 'find'
require 'yaml'
require 'libxml'
require 'pp'
require 'executor'
require 'digest/md5'
require 'configuration'

# Class PackageValidator
# Author: Manny Rodriguez
#
# --------------------------
# The PackageValidator class validates a package and returns a hash with the results.
#
# The validation tasks are, in order: 
# * Validation of package syntax 
# * Account/Project verification 
# * SIP descriptor validation (after retriving files needed for validation from the XML resolution service)
# * Look for and record any undescribed files
# * Virus check described files
# * Verify checksums for described files
#
# Returns a hash containing validation results.
#
# SAMPLE USAGE:
#
# validator = PackageValidator.new
# results = validator.validate_package /path/to/package
#
# NOTES:
# If *BOTH* PACKAGE_NAME.xml and PACKAGE_NAME.XML are present, PACKAGE_NAME.XML will be treated as a content file

class ValidationFailed < StandardError; end

class PackageValidator

  def initialize
    @package_paths_array = []
    @descriptor_path = ""
    @descriptor_document
    @result = {}

    # tell the LibXML parser to ignore whitespace
    LibXML::XML.default_keep_blanks = false
  end

  # runs all validation tasks on a package, building an XML report as the validation progresses.
  # report is returned after validation completes.
  # if a failure prevents the running of all checks, a report containing all checks performed is returned
  
  def validate_package(path_to_package)
    begin
      validate_package_syntax path_to_package
      validate_descriptor
      validate_account_project
      # find undescribed files here
      virus_check_clean = virus_check
      checksums_match = validate_checksums

    # any ValidationFailed exceptions caught indicate a problem with the package 
    rescue ValidationFailed
      @result["outcome"] = "failure"

    # any other exceptions caught will result in report indicating failure to complete validation
    rescue => e
      @result["outcome"] = "failure"
    end

    # no exceptions caught mean no fatal errors, let's see what happened with the virus and checksum checks
    if virus_check_clean && checksums_match
      @result["outcome"] = "success"
    else
      @result["outcome"] = "failure"
    end

    # return result hash
    return @result
  end

  private 

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
    @result["syntax"] = {}

    validate_syntax_path_is_dir(path_to_package)
    validate_syntax_descriptor_exists(path_to_package)
    validate_syntax_descriptor_is_file(path_to_package)
    validate_syntax_content_file_present(path_to_package)
  end

  # checks that path to package specified is a directory
  # takes a node syntax_report_node, and path to package
  # on success, adds appropriate values to hash
  # on failure, adds appropriate values to hash and raises exception

  def validate_syntax_path_is_dir path_to_package
    if not File.directory? path_to_package
      @result["syntax"]["package_is_directory"] = "failure"
      raise StandardError, "Specified path is not a directory"
    else
      @result["syntax"]["package_is_directory"] = "success"
    end
  end

  # checks that a descriptor of form PACKAGE_NAME.xml/XML exists
  # takes a node syntax_report_node, and path to package
  # on success, adds appropriate values to hash
  # on failure, adds appropriate values to hash and raises exception

  def validate_syntax_descriptor_exists path_to_package
    # get a list of the files therein and put it into an array
    Find.find(path_to_package) do |stuff|
      @package_paths_array.push stuff
    end

    package_basename = File.basename @package_paths_array[0]

    # the value at index 0 is always the directory name, so we look for a file named package_file_array[0].xml
    if @package_paths_array.include? "#{@package_paths_array[0]}/#{package_basename}.xml"
      @descriptor_path = "#{@package_paths_array[0]}/#{package_basename}.xml"
      @result["syntax"]["descriptor_found"] = "success"

      # if we didn't find PACKAGE_NAME.xml, there is still the possibility we have PACAKGE_NAME.XML
    elsif @package_paths_array.include? "#{@package_paths_array[0]}/#{package_basename}.XML"
      @descriptor_path = "#{@package_paths_array[0]}/#{package_basename}.XML"
      @result["syntax"]["descriptor_found"] = "success"

    else
      @result["syntax"]["descriptor_found"] = "failure"
      raise StandardError, "Expected SIP descriptor not found"
    end
  end

  # checks that descriptor is a file
  # takes a node syntax_report_node, and path to package
  # on success, adds appropriate values to hash
  # on failure, adds appropriate values to hash and raises exception

  def validate_syntax_descriptor_is_file path_to_package
    if File.file? @descriptor_path
      @result["syntax"]["descriptor_is_file"] = "success"
    else
      @result["syntax"]["descriptor_is_file"] = "failure"
      raise StandardError, "SIP descriptor is not a file"
    end
  end

  # checks that at least one content file is present in the package
  # takes a node syntax_report_node, and path to package
  # on success, adds appropriate values to hash
  # on failure, adds appropriate values to hash and raises exception
  # ignores files with .svn in their path

  def validate_syntax_content_file_present path_to_package
    content_file_found = false

    @package_paths_array.each do |path|
      next if path =~ /.svn/

      next if path == @descriptor_path
      content_file_found = true if File.file? path
      break if content_file_found == true
    end

    if content_file_found
      @result["syntax"]["content_file_found"] = "success"
    else
      @result["syntax"]["content_file_found"] = "failure"
      raise StandardError, "No content files found"
    end
  end


  # checks that the specified account/project in the package is valid
  # TODO: implement

  def validate_account_project 
    @result["account_project_validation"] = {}
    @result["account_project_validation"]["account_project_valid"] = "test_not_implemented"
  end

  # passes descriptor to XML validation service
  # TODO: implement, once we have an XML validation service
  def validate_descriptor
    @result["descriptor_validation"] = {}
    @result["descriptor_validation"]["descriptor_valid"] = "test_not_implemented"

    # for now, we have to assume the descriptor is valid
    @descriptor_document = LibXML::XML::Document.file @descriptor_path
  end

  # runs a virus check on the package
  # Iterates over all files in package, calling Configuration.instance.values["virus_checker_executable"] for each one
  # returns true if all clean, false otherwise
  # ignores files with .svn in the path
  
  def virus_check
    @result["virus_check"] = {}

    all_ok = true

    @package_paths_array.each do |path|
      next if path =~ /.svn/

      if File.file? path
        summary = Executor.execute_return_summary "#{Configuration.instance.values["virus_checker_executable"]} #{path}"
        package_path = path.gsub(@package_paths_array[0] + "/", "")

        # inspect the exit status of the virus checker to see what the result is for this file

        case summary["exit_status"]

          # success
        when Configuration.instance.values["virus_exit_status_clean"]
          @result["virus_check"][package_path] = {}

          @result["virus_check"][package_path]["outcome"] = "success"
          @result["virus_check"][package_path]["virus_checker_executable"] = Configuration.instance.values["virus_checker_executable"]

          # virus found
        when Configuration.instance.values["virus_exit_status_infected"]
          @result["virus_check"][package_path] = {}

          @result["virus_check"][package_path]["outcome"] = "failure"
          @result["virus_check"][package_path]["virus_checker_executable"] = Configuration.instance.values["virus_checker_executable"]

          if summary['STDOUT'] != nil
            @result["virus_check"][package_path]["STDOUT"] = summary['STDOUT']
          else
            @result["virus_check"][package_path]["STDOUT"] = ""
          end

          if summary['STDERR'] != nil
            @result["virus_check"][package_path]["STDERR"] = summary['STDERR']
          else
            @result["virus_check"][package_path]["STDERR"] = ""
          end

          all_ok = false

          # non-zero exit status that is not the success case
        else
          @result["virus_check"][package_path] = {}

          @result["virus_check"][package_path]["outcome"] = "indeterminate"
          @result["virus_check"][package_path]["virus_checker_executable"] = Configuration.instance.values["virus_checker_executable"]

          if summary['STDOUT'] != nil
            @result["virus_check"][package_path]["STDOUT"] = summary['STDOUT']
          else
            @result["virus_check"][package_path]["STDOUT"] = ""
          end

          if summary['STDERR'] != nil
            @result["virus_check"][package_path]["STDERR"] = summary['STDERR']
          else
            @result["virus_check"][package_path]["STDERR"] = ""
          end

          all_ok = false
        end
      end # of if
    end # of loop

    return all_ok
  end # of method virus_check

  # checks content file checksums against descriptor specified checksum values
  # returns true if all match, false otherwise
  # TODO: check CHECKSUMTYPE attribute, and calcuate accordingly
  
  def validate_checksums
    @result["checksum_check"] = {}
    all_ok = true

    file_nodes = @descriptor_document.find('//METS:file').to_a

    # iterate through all the file nodes, ensuring that all described files are present, and checksums match (if provided in descriptor)
    file_nodes.each do |file_node|
      file_node_attributes = file_node.attributes

      flocat_node = file_node.child
      flocat_node_attributes = flocat_node.attributes

      file_path = File.join @package_paths_array[0], flocat_node_attributes["href"]
      described_checksum = file_node_attributes["CHECKSUM"]

      @result["checksum_check"][flocat_node_attributes["href"]] = {}

      # check to see that the file exists, report accordingly
      if File.exists? file_path
        @result["checksum_check"][flocat_node_attributes["href"]]["file_exists"] = "success"

        # if a described checksum is present in descriptor, compute the checksum for the file.
        # Otherwise, set variable computed_checksum == described_checksum == nil so that equality test in next statement passes
        if described_checksum
          computed_checksum = compute_file_checksum file_path
        else
          computed_checksum = described_checksum
        end

        if computed_checksum.upcase == described_checksum.upcase
          @result["checksum_check"][flocat_node_attributes["href"]]["checksum_match"] = "success"
        else
          @result["checksum_check"][flocat_node_attributes["href"]]["checksum_match"] = "failure"
          @result["checksum_check"][flocat_node_attributes["href"]]["described"] = described_checksum.upcase
          @result["checksum_check"][flocat_node_attributes["href"]]["computed"] = computed_checksum.upcase

          all_ok = false
        end
      else
        @result["checksum_check"][flocat_node_attributes["href"]]["file_exists"] = "failure"

        all_ok = false
      end

    end # of loop

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
