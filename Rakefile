require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'


Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  # t.rcov = true
end

task :default => [:spec]
