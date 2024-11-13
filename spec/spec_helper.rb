# frozen_string_literal: true

require "simplecov"
require "coradoc"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  SimpleCov.profiles.define "gem" do
    add_filter "/spec/"
    add_filter "/autotest/"
    add_group "Libraries", "/lib/"
  end
  SimpleCov.start "gem"

  # Input::HTML:
  config.after(:each) do
    Coradoc::Input::HTML.instance_variable_set(:@config, nil)
  end
end

# Input::HTML:
require "coradoc/input/html"
require "coradoc/input/html/html_converter"
require "word-to-markdown"

Dir[File.join("spec", "**", "support", "**", "*.rb")]
  .each { |f| require File.join(".", f) }

def node_for(html)
  Nokogiri::HTML.parse(html).root.child.child
end

# Parser::Markdown:
def markdown_example(name, source, expected_result, opts={})
  it "parses example #{name}" do
    expect(subject.parse_with_debug(source)).to eq(expected_result)
  end
  it "parses example #{name} stripped" do
    expect(subject.parse_with_debug(source.strip)).to eq(expected_result)
  end if (opts[:strip].nil? ? true : opts[:strip])
end
