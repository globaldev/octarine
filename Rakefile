# default task
task :default => :test

#
# Test::Unit
#
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :test do
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << "lib"
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end
end
