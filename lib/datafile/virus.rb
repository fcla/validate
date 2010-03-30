require 'xmlns'
require 'daitss/config'

class DataFile

  # returns array [ CHECK_PASSED (boolean), SCANNER_OUTPUT ]
  def virus_check
    raise "CONFIG not set" unless ENV['CONFIG']
    Daitss::CONFIG.load ENV['CONFIG']
    
    output = `#{Daitss::CONFIG['virus-scanner-executable']} #{datapath} 2>&1`

    [ $?.exitstatus == 0, output ]
  end
end
