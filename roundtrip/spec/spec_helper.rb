# frozen_string_literal: true

require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'coradoc/roundtrip'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :defined
end
