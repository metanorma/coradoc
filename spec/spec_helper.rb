# frozen_string_literal: true

require 'bundler/setup'
require 'coradoc'
require 'coradoc/input'
require 'coradoc/asciidoc'
require 'coradoc/html'
require 'coradoc/markdown'
require 'coradoc/markdown/parser/ast_processor'
require 'coradoc/docx' if Gem.loaded_specs.key?('coradoc-docx')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Filter examples based on focus (use fit/fdescribe/fcontext to focus)
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true

  # Skip benchmark tests unless BENCHMARK=true
  config.filter_run_excluding type: :benchmark unless ENV['BENCHMARK'] == 'true'
end

# Define the markdown_example helper for Markdown parser specs
# This is needed when running markdown specs from monorepo root
module MarkdownExampleHelper
  # Helper to convert Parslet::Slice objects to plain strings
  # This is a module_function so it can be called from within it blocks

  module_function

  def convert_slices_to_strings(obj)
    case obj
    when Parslet::Slice
      obj.to_s
    when Hash
      obj.transform_values { |v| convert_slices_to_strings(v) }
    when Array
      obj.map { |v| convert_slices_to_strings(v) }
    else
      obj
    end
  end

  def markdown_example(number, markdown, expected_ast, strip: true)
    it "parses example #{number}" do
      content = strip ? "#{markdown.strip}\n" : markdown
      result = described_class.new.parse(content)
      # Apply post-processing (escape sequences, etc.)
      processor = Coradoc::Markdown::Parser::AstProcessor
      processed = processor.process(result)
      # Convert any remaining Parslet::Slice to strings for comparison
      # Use the module_function directly since we're inside an it block
      result = MarkdownExampleHelper.convert_slices_to_strings(processed)
      expect(result).to eq(expected_ast)
    end
  end
end

RSpec.configure do |config|
  config.extend MarkdownExampleHelper
end
