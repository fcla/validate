require 'configuration'

describe Configuration do
  
  # These tests verify that the configuration variables we expect are exposed as methods of the Configuration singleton class
  
  it "Configuration.instance.values should be a hash" do
    Configuration.instance.values.should(respond_to("[]="))
  end

end
