require 'xmlns'
require 'daitss/config'

class VirusFound < StandardError; end
class VirusScanFailed < StandardError; end

class DataFile

  # returns true if no virus found
  # raises exception if virus found or if scanner returns non-zero exit status
  def virus_check
    raise "CONFIG not set" unless ENV['CONFIG']
    Daitss::CONFIG.load ENV['CONFIG']
    
    output = `#{Daitss::CONFIG['virus-scanner-executable']} #{datapath} 2>&1`

    if $?.exitstatus == 0
      true
    elsif $?.exitstatus == 1
      raise VirusFound, output
    else
      raise VirusScanFailed, output
    end
  end
end
