# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::ParseError do
  describe '.new' do
    it 'creates an error with message' do
      error = described_class.new('Test error')

      expect(error.message).to include('Test error')
    end

    it 'creates an error with line number' do
      error = described_class.new('Test error', line: 42)

      expect(error.line).to eq(42)
      expect(error.message).to include('line 42')
    end

    it 'creates an error with line and column' do
      error = described_class.new('Test error', line: 10, column: 5)

      expect(error.line).to eq(10)
      expect(error.column).to eq(5)
      expect(error.message).to include('line 10, column 5')
    end

    it 'creates an error with source line' do
      error = described_class.new('Test error', source_line: 'some code here')

      expect(error.source_line).to eq('some code here')
      expect(error.message).to include('some code here')
    end

    it 'creates an error with suggestion' do
      error = described_class.new('Test error', suggestion: 'Try this instead')

      expect(error.suggestion).to eq('Try this instead')
      expect(error.message).to include('Suggestion: Try this instead')
    end

    it 'creates an error with column pointer' do
      error = described_class.new(
        'Test error',
        source_line: 'abc def ghi',
        column: 5
      )

      expect(error.message).to include('^')
    end
  end

  describe '#build_full_message' do
    it 'includes all context information' do
      error = described_class.new(
        'Parse failed',
        line: 10,
        column: 3,
        source_line: 'invalid syntax',
        suggestion: 'Check your syntax'
      )

      message = error.message

      expect(message).to include('Parse failed')
      expect(message).to include('line 10')
      expect(message).to include('column 3')
      expect(message).to include('invalid syntax')
      expect(message).to include('Suggestion: Check your syntax')
    end
  end

  describe '.from_parslet' do
    it 'creates ParseError from Parslet exception' do
      parslet_error = Parslet::ParseFailed.new('Expected something')

      error = described_class.from_parslet(parslet_error)

      expect(error).to be_a(described_class)
      expect(error.message).to include('Expected something')
    end

    it 'preserves cause exception' do
      parslet_error = Parslet::ParseFailed.new('Parse failed')

      error = described_class.from_parslet(parslet_error)

      expect(error.cause).to eq(parslet_error)
    end
  end

  describe '.extract_source_line' do
    it 'extracts line from source' do
      source = "line 1\nline 2\nline 3"

      result = described_class.extract_source_line(source, 2)

      expect(result).to eq('line 2')
    end

    it 'returns nil for out of bounds' do
      source = 'only one line'

      expect(described_class.extract_source_line(source, 10)).to be_nil
      expect(described_class.extract_source_line(source, 0)).to be_nil
    end

    it 'returns nil for nil source' do
      expect(described_class.extract_source_line(nil, 1)).to be_nil
    end
  end

  describe '.generate_suggestion' do
    it 'suggests fix for heading errors' do
      error = double(message: 'Expected heading')

      suggestion = described_class.generate_suggestion(error)

      expect(suggestion).to include('headings')
    end

    it 'suggests fix for list errors' do
      error = double(message: 'Expected list item')

      suggestion = described_class.generate_suggestion(error)

      expect(suggestion).to include('List items')
    end

    it 'suggests fix for table errors' do
      error = double(message: 'Expected table delimiter')

      suggestion = described_class.generate_suggestion(error)

      expect(suggestion).to include('Tables')
    end

    it 'suggests fix for attribute errors' do
      error = double(message: 'Expected attribute')

      suggestion = described_class.generate_suggestion(error)

      expect(suggestion).to include('Attributes')
    end

    it 'returns nil for unknown errors' do
      error = double(message: 'Unknown error type')

      expect(described_class.generate_suggestion(error)).to be_nil
    end
  end

  describe 'inheritance' do
    it 'inherits from Coradoc::AsciiDoc::Error' do
      error = described_class.new('test')

      expect(error).to be_a(Coradoc::AsciiDoc::Error)
      expect(error).to be_a(StandardError)
    end
  end
end
