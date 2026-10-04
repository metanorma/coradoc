# frozen_string_literal: true

require 'rspec/its'
require 'simplecov'

# The suite exercises the portable Leptris FFI surface (same choice the
# leptris gem's own suite makes); platform native acceleration is
# orthogonal to these specs.
ENV['LEPTRIS_NO_NATIVE'] ||= '1'

# Require the main coradoc gem first
require 'coradoc'

# Require coradoc-asciidoc for AsciiDoc model classes (used by converters)
require 'coradoc/asciidoc'

# Then require coradoc-html gem
require 'coradoc/html'

# Convenience alias for specs
CoreModel = Coradoc::CoreModel

# Set up SimpleCov for coverage
SimpleCov.profiles.define 'gem' do
  add_filter '/spec/'
  add_filter '/autotest/'
  add_group 'Libraries', '/lib/'
end
SimpleCov.start 'gem'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random

  config.before(:context, :requires_frontend_dist) do
    dist_dir = File.expand_path('../frontend/dist', __dir__)
    skip 'Frontend dist not built. Run: cd frontend && npm install && npm run build' unless File.directory?(dist_dir)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Clean up after each test
  config.after do
    Coradoc::Html.reset_input_config!
  end
end

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')]
  .each { |f| require File.expand_path(f) }

# Load shared examples
Dir[File.join(__dir__, 'coradoc', 'html', 'drop', 'shared_*.rb')]
  .each { |f| require File.expand_path(f) }

# Helper method to get an element node from HTML
def node_for(html)
  Leptris::HTML.parse(html).root&.child&.child
end

# Helper to parse an HTML fragment; returns the <body> element wrapping it.
def html_fragment(html)
  Leptris::HTML.parse(html).at_css('body')
end
