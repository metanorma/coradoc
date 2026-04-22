# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# Kramdown test runner for coradoc-markdown
#
# This spec runs tests ported from the kramdown test suite.
# Each test has a .text file (markdown input) and a .html file (expected HTML output).
#
# We test by:
# 1. Parsing the markdown to AST
# 2. Verifying the AST is valid (no parse errors)
# 3. Optionally comparing AST structure for specific test cases

# Test categories to exclude (not relevant for our parser)
EXCLUDED_TESTS = %w[
  man/
].freeze

# Tests that are expected to fail (parser limitations)
# Note: IAL, ALD, extensions, math, and HTML markdown attr are now implemented
PENDING_TESTS = %w[].freeze

def find_test_files
  spec_dir = File.dirname(__FILE__)
  fixtures_dir = File.join(spec_dir, 'fixtures', 'kramdown')
  Dir[File.join(fixtures_dir, '**', '*.text')].sort
end

def excluded?(test_path)
  EXCLUDED_TESTS.any? { |ex| test_path.include?(ex) }
end

def pending?(test_path)
  PENDING_TESTS.any? { |ex| test_path.include?(ex) }
end

def load_test_case(text_file)
  html_file = text_file.sub(/\.text$/, '.html')
  options_file = text_file.sub(/\.text$/, '.options')

  {
    text: File.read(text_file, encoding: 'UTF-8'),
    html: File.exist?(html_file) ? File.read(html_file, encoding: 'UTF-8') : nil,
    options: File.exist?(options_file) ? YAML.load_file(options_file) : {}
  }
end

def parse_markdown(text)
  Coradoc::Markdown.parse(text)
end

# Generate tests dynamically
RSpec.describe 'Kramdown Test Suite' do
  find_test_files.each do |text_file|
    relative_path = text_file.sub(%r{.*spec/fixtures/kramdown/}, '')

    next if excluded?(relative_path)

    test_name = relative_path.sub(/\.text$/, '').tr('/', '_')

    if pending?(relative_path)
      xit "parses #{test_name}" do
        # Pending test
      end

      next
    end

    it "parses #{test_name}" do
      test_case = load_test_case(text_file)

      # Parse should not raise errors
      expect do
        result = parse_markdown(test_case[:text])
        expect(result).not_to be_nil
      end.not_to raise_error
    end
  end
end
