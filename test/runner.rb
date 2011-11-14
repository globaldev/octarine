require 'simplecov'
SimpleCov.start do
  add_filter "test"
  add_filter "vendor"
end

Dir[File.expand_path("../**/*_test.rb", __FILE__)].each {|test| require test}
