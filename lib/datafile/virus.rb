require 'xmlns'

class DataFile

  # returns array [ CHECK_PASSED (boolean), SCANNER_OUTPUT ]
  def virus_check
    output = `#{Daitss::CONFIG['virus-scanner-executable']} #{datapath} 2>&1`
    [ $?.exitstatus == 0, output ]
  end
end
