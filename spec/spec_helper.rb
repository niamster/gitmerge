$ERROR_INFO = nil

require 'rubygems'
require 'bundler/setup'
require 'simplecov'
require 'coveralls'

Coveralls.wear!
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

require 'gitmerge'

Dir['./spec/support/*.rb'].map { |f| require f }

RSpec.configure(&:disable_monkey_patching!)
