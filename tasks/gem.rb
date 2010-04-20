require 'rake/gempackagetask'

spec = Gem::Specification.new do |spec|
  spec.name = "daitss-validate"
  spec.version = '2.0.0'
  spec.summary = "Validation service for DAITSS 2"
  spec.authors = ["Emmanuel Rodriguez", "Francesco Lazzarino"]
  spec.files = Dir["spec/*", "lib/*", "Rakefile", "tasks/*", "views/*", "app.rb"]
  spec.add_dependency "sinatra"
  spec.bindir = 'bin'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end


