require 'tempfile'
require 'rjb'

class JValidator

  JAR_FILE = File.join File.dirname(__FILE__), '..', 'ext', 'xmlvalidator.jar'

  def initialize src
    @src = src

    # setup rjb validator
    ENV['CLASSPATH'] = if ENV['CLASSPATH']
                         "#{JAR_FILE}:#{ENV['CLASSPATH']}"
                       else
                         JAR_FILE
                       end

    # can probably make this a class variable
    @j_File = Rjb.import 'java.io.File' 
    @j_Validator = Rjb.import 'edu.fcla.da.xml.Validator'
    @jvalidator = @j_Validator.new
  end

  def results

    tio = Tempfile.open 'jxmlvalidator'
    tio.write @src
    tio.flush
    tio.close

    # java code
    jfile = @j_File.new tio.path
    jchecker = @jvalidator.validate jfile

    tio.unlink

    # formedness errors
    rs = (0...jchecker.getFatals.size).map do |n|
      f = jchecker.getFatals.elementAt(n)

      { :level => 'fatal',
        :line => f.getLineNumber, 
        :message => f.getMessage, 
        :column => f.getColumnNumber }

    end

    # validation errors
    rs += (0...jchecker.getErrors.size).map do |n|
      e = jchecker.getErrors.elementAt(n)

      { :level => 'error',
        :line => e.getLineNumber, 
        :message => e.getMessage,
        :column => e.getColumnNumber }

    end


  end

end

