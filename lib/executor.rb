require 'open4'

# Class Executor
# Author: Manny Rodriguez
#
# --------------------------
# The Executor class encapsulates the execution of a running program.
#
# SAMPLE USAGE:
#
# returns any STDERR output, raises exception with STDERR output if exit status is not zero
# Executor.execute_expect_zero "/usr/bin/true" 
# Executor.execute_expect_zero "/usr/bin/false" 
#
# executes command and returns a hash with summary variables, such as exit status, STDERR, STDOUT
# Executor.execute_return_summary "/usr/bin/clamscan /home" 
#
# NOTES:
#
# In the case that the command passed in cannot be executed (does not exist, or appropriate permissions are not set)
# then an Errno::ENO* type exception will be raised by the Open4 class.

class ExecutionError < StandardError; end

class Executor
  # raises exception if exit status is not zero. Otherwise, any STDOUT output is returned
  def self.execute_expect_zero(command)
    errors = ""
    output = ""

    process = Open4::popen4(command) do |pid, stdin, stdout, stderr|
      errors = stderr.gets
      output = stdout.gets
    end

    raise ExecutionError, errors unless process.exitstatus == 0

    return output
  end

  # simply returns a hash containing process execution summary, including exit status, STDOUT, and STDERR
  # summary["exit_status"] = process exit status
  # summary["STDERR"] = STDERR output
  # summary["STDOUT"] = STDOUT output
  def self.execute_return_summary(command)
    errors = ""
    output = ""

    process = Open4::popen4(command) do |pid, stdin, stdout, stderr|
      errors = stderr.gets
      output = stdout.gets
    end

    summary = {}
    summary["exit_status"] = process.exitstatus
    summary["STDOUT"] = output
    summary["STDERR"] = errors

    return summary
  end
end
