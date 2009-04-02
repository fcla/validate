Gem::Specification.new do |spec|
  spec.name = "daitss-validate"
  spec.version = '1.0.0'
  spec.summary = "Validation service for DAITSS 2"
  spec.authors = ["Emmanuel Rodriguez"]
  spec.files = Dir["spec/*", "lib/*", "bin/*", "etc/*", "Rakefile", "daitss-validate.gemspec"]
  spec.add_dependency "sinatra"
  spec.bindir = 'bin'
end
