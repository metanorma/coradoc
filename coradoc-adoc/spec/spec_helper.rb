# frozen_string_literal: true

# Add local lib directory to load path FIRST
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'bundler/setup'

# Load coradoc core first (which includes Logger)
require 'coradoc'

# Now load our asciidoc module
require 'coradoc/asciidoc'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
end
