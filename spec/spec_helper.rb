$ERROR_INFO = 1

require 'rubygems'
require 'bundler/setup'
require 'coveralls'
Coveralls.wear_merged!
SimpleCov.merge_timeout 3600
SimpleCov.command_name 'spec'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

require 'gitmerge'
Dir['./spec/support/*.rb'].map { |f| require f }

RSpec.configure(&:disable_monkey_patching!)
