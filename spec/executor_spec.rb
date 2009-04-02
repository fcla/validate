require 'executor'
require 'pp'

describe Executor do
  
  it "execute_expect_zero should return STDOUT if exit status is zero" do
    stdout = Executor.execute_expect_zero "echo foo"
    stdout.should == "foo\n"
  end


  it "execute_expect_zero should raise ExecutionError if exit status is non-zero" do
    lambda { Executor.execute_expect_zero "/usr/bin/false" }.should raise_error(ExecutionError)
  end

  it "execute_expect_zero should raise execption if error found executing passed command" do
    lambda { Executor.execute_expect_zero "foo" }.should raise_error
  end

  it "execute_return_summary return a hash containing exit status, stdout, and stderr if exit status is zero" do
    summary = Executor.execute_return_summary "echo foo"

    summary["exit_status"].should == 0
    summary["STDERR"].should == nil
    summary["STDOUT"].should == "foo\n"
  end
  
  it "execute_return_summary return a hash containing exit status, stdout, and stderr if exit status is non-zero" do
    summary = Executor.execute_return_summary "echo foo; echo bar 1>&2; /usr/bin/false"

    summary["exit_status"].should == 1
    summary["STDERR"].should == "bar\n"
    summary["STDOUT"].should == "foo\n"
  end
  
  it "execute_return_summary should raise execption if error found executing passed command" do
    lambda { Executor.execute_return_summary "foo" }.should raise_error
  end
end
