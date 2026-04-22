# frozen_string_literal: true

require 'rspec/its'
require 'simplecov'

# Require the main coradoc gem first
require 'coradoc'

# Require coradoc-asciidoc for AsciiDoc model classes (used by converters)
require 'coradoc/asciidoc'

# Then require coradoc-html gem
require 'coradoc/html'

# Set up SimpleCov for coverage
SimpleCov.profiles.define 'gem' do
  add_filter '/spec/'
  add_filter '/autotest/'
  add_group 'Libraries', '/lib/'
end
SimpleCov.start 'gem'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Clean up after each test
  config.after do
    # Reset Input::Html config if it was used
    if defined?(Coradoc::Input::Html)
      begin
        Coradoc::Input::Html.instance_variable_set(:@config, nil)
      rescue StandardError
        nil
      end
    end
  end
end

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')]
  .each { |f| require File.expand_path(f) }

# Helper method to get Nokogiri node from HTML
def node_for(html)
  Nokogiri::HTML.parse(html).root&.child&.child
end
