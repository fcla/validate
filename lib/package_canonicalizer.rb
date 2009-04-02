require 'executor'
require 'configuration'

# Class PackageCanonicalizer
# Author: Manny Rodriguez
#
# --------------------------
# The PackageCanonicalizer class encapsulates package canonicalization tasks
#
# These tasks include: unzipping/untarring
#
# SAMPLE USAGE:
#
# canonicalizer = PackageCanonicalizer.new
#
# untars /UF0000001.tar to /var/daitss/processing
# canonicalizer.unwrap_package /var/daitss/incoming/UF0000001.tar /var/daitss/processing
#
# unzips /UF0000002.zip to /var/daitss/processing
# canonicalizer.unwrap_package /var/daitss/incoming/UF0000002.zip /var/daitss/processing
#
# NOTES:
#
# Zip or tar files are expected to have a .zip or .tar extension
# CanonicalizationExecutionError is raised if calls to the unzip or untar utilities exit with non-zero status
# CanonicalizationParameterError is raised if the parameters passed in fail sanity checks 

class CanonicalizationParameterError < StandardError; end
  
class PackageCanonicalizer

  # untars or unzips (as appropriate) a package
  def unwrap_package(path_to_wrapped_package, unwrap_destination)

    # standard checks on inputted input and output paths
    raise CanonicalizationParameterError, "No file exists at input path provided" unless File.exists? path_to_wrapped_package and File.file? path_to_wrapped_package
    raise CanonicalizationParameterError, "Read access denied for input path provided" unless File.readable? path_to_wrapped_package 
    raise CanonicalizationParameterError, "Output path provided does not exist, or is not a directory" unless File.exists? unwrap_destination and File.directory? unwrap_destination
    raise CanonicalizationParameterError, "Write access denied for output path provided" unless File.writable? unwrap_destination

   #TODO: better zip/tar detection 
    if path_to_wrapped_package =~ /.zip/
      unzip_package path_to_wrapped_package, unwrap_destination
    elsif path_to_wrapped_package =~ /.tar/
      untar_package path_to_wrapped_package, unwrap_destination
    else
      raise CanonicalizationParameterError, " File at path provided does not seem to point to either a zip or tar file."
    end
  end

  private

  def unzip_package(path_to_wrapped_package, unwrap_destination)

    # argument list to extract zip file to a specified directory
    args = " " +  path_to_wrapped_package + " -d " + unwrap_destination 

    Executor.execute_expect_zero Configuration.instance.unzip_executable_path + args
  end

  def untar_package(path_to_wrapped_package, unwrap_destination)

    # argument list to extract tar file to a specified directory
    args = " -xf " +  path_to_wrapped_package + " -C " + unwrap_destination 

    Executor.execute_expect_zero Configuration.instance.tar_executable_path + args
  end

end # of class PackageCanonicalizer
