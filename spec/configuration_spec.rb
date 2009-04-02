require 'configuration'

describe Configuration do
  
  # These tests verify that the configuration variables we expect are exposed as methods of the Configuration singleton class
  
  it "should expose virus_checker_executable config variable as virus_checker_executable method" do
    lambda { Configuration.instance.virus_checker_executable }.should_not raise_error(NoMethodError)
  end

  it "should expose virus_exit_status_infected config variable as virus_exit_status_infected method" do
    lambda { Configuration.instance.virus_exit_status_infected }.should_not raise_error(NoMethodError)
  end

  it "should expose virus_exit_status_clean config variable as virus_exit_status_clean method" do
    lambda { Configuration.instance.virus_exit_status_clean }.should_not raise_error(NoMethodError)
  end

  it "should expose tar_executable_path config variable as tar_executable_path method" do
    lambda { Configuration.instance.tar_executable_path }.should_not raise_error(NoMethodError)
  end

  it "should expose unzip_executable_path config variable as unzip_executable_path method" do
    lambda { Configuration.instance.unzip_executable_path }.should_not raise_error(NoMethodError)
  end

  it "should expose METS schema location as mets_schema_location method" do
    lambda { Configuration.instance.mets_schema_location }.should_not raise_error(NoMethodError)
  end

  it "should expose temp directory location as temp_dir method" do
    lambda { Configuration.instance.temp_dir }.should_not raise_error(NoMethodError)
  end
end
