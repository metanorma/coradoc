# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::ParseError do
  describe '#initialize' do
    it 'creates a basic error message' do
      error = described_class.new('Test error')

      expect(error.message).to eq('Test error')
    end

    it 'includes line number in message' do
      error = described_class.new('Test error', line: 10)

      expect(error.message).to include('line 10')
    end

    it 'includes column number in message' do
      error = described_class.new('Test error', column: 5)

      expect(error.message).to include('column 5')
    end

    it 'includes both line and column' do
      error = described_class.new('Test error', line: 10, column: 5)

      expect(error.message).to include('line 10')
      expect(error.message).to include('column 5')
    end
  end

  describe '#message_with_context' do
    let(:source) { "Line 1\nLine 2\nLine 3\nLine 4\nLine 5" }

    it 'returns basic message without source' do
      error = described_class.new('Test error')

      expect(error.message_with_context).to eq('Test error')
    end

    it 'includes source snippet with source and line' do
      error = described_class.new('Test error', source: source, line: 3)

      expect(error.message_with_context).to include('Test error')
      expect(error.message_with_context).to include('Line 3')
    end

    it 'shows context lines around error' do
      error = described_class.new('Test error', source: source, line: 3, snippet_lines: 1)

      context = error.message_with_context
      expect(context).to include('Line 2')
      expect(context).to include('Line 3')
      expect(context).to include('Line 4')
    end

    it 'shows column indicator' do
      error = described_class.new('Test error', source: source, line: 3, column: 3)

      expect(error.message_with_context).to include('^')
    end
  end

  describe '#source_snippet' do
    it 'returns empty string without source' do
      error = described_class.new('Test')

      expect(error.source_snippet).to eq('')
    end

    it 'marks the error line with >>>' do
      source = "First line\nSecond line\nThird line"
      error = described_class.new('Test', source: source, line: 2)

      snippet = error.source_snippet
      expect(snippet).to include('>>>')
      expect(snippet).to include('Second line')
    end

    it 'includes line numbers' do
      source = "Line one\nLine two"
      error = described_class.new('Test', source: source, line: 1)

      expect(error.source_snippet).to match(/\d+:/)
    end
  end

  describe '#suggestion' do
    it 'returns nil when no suggestion matches' do
      error = described_class.new('Generic error')
      expect(error.suggestion).to be_nil
    end

    it 'returns suggestion for unterminated string errors' do
      error = described_class.new('Unexpected end of input')
      expect(error.suggestion).to include('unclosed quotes')
    end

    it 'returns suggestion for indentation errors' do
      error = described_class.new('Unexpected indentation error')
      expect(error.suggestion).to include('indentation')
    end

    it 'returns suggestion for heading errors' do
      error = described_class.new('Invalid heading level')
      expect(error.suggestion).to include('heading')
    end

    it 'returns suggestion for list errors' do
      error = described_class.new('Invalid list marker')
      expect(error.suggestion).to include('list')
    end

    it 'returns suggestion for link errors' do
      error = described_class.new('Invalid link syntax')
      expect(error.suggestion).to include('link')
    end

    it 'accepts explicit suggestion' do
      error = described_class.new('Error', suggestion: 'Try this')
      expect(error.suggestion).to eq('Try this')
    end
  end

  describe '#all_suggestions' do
    it 'returns empty array when no suggestions match' do
      error = described_class.new('Generic error')
      expect(error.all_suggestions).to eq([])
    end

    it 'returns matching suggestions from message' do
      error = described_class.new('Invalid heading level')
      suggestions = error.all_suggestions
      expect(suggestions).not_to be_empty
      expect(suggestions.first).to include('heading')
    end

    it 'returns unique suggestions' do
      error = described_class.new('Invalid heading level and heading syntax')
      suggestions = error.all_suggestions
      expect(suggestions.uniq).to eq(suggestions)
    end
  end

  describe '#message_with_context with suggestions' do
    it 'includes suggestion when available' do
      source = "Line one\nInvalid heading\nLine three"
      error = described_class.new(
        'Invalid heading level',
        source: source,
        line: 2
      )

      expect(error.message_with_context).to include('Suggestion:')
      expect(error.message_with_context).to include('heading')
    end
  end
end

RSpec.describe Coradoc::ValidationError do
  describe '#initialize' do
    it 'creates a basic validation error' do
      error = described_class.new('Validation failed')

      expect(error.message).to eq('Validation failed')
    end

    it 'includes list of errors' do
      error = described_class.new(
        'Validation failed',
        errors: ['Missing title', 'Empty section']
      )

      expect(error.message).to include('Missing title')
      expect(error.message).to include('Empty section')
    end
  end

  describe '#errors' do
    it 'returns the list of errors' do
      error = described_class.new('Test', errors: ['Error 1', 'Error 2'])

      expect(error.errors).to eq(['Error 1', 'Error 2'])
    end

    it 'defaults to empty array' do
      error = described_class.new('Test')

      expect(error.errors).to eq([])
    end
  end
end

RSpec.describe Coradoc::TransformationError do
  describe '#initialize' do
    it 'creates a basic transformation error' do
      error = described_class.new('Transform failed')

      expect(error.message).to eq('Transform failed')
    end

    it 'includes source type' do
      error = described_class.new('Failed', source_type: 'Paragraph')

      expect(error.message).to include('source: Paragraph')
    end

    it 'includes target type' do
      error = described_class.new('Failed', target_type: 'Block')

      expect(error.message).to include('target: Block')
    end

    it 'includes both source and target' do
      error = described_class.new(
        'Failed',
        source_type: 'Paragraph',
        target_type: 'Block'
      )

      expect(error.message).to include('source: Paragraph')
      expect(error.message).to include('target: Block')
    end
  end
end

RSpec.describe Coradoc::UnsupportedFormatError do
  describe '#initialize' do
    it 'creates an error for unsupported format' do
      error = described_class.new(:docx)

      expect(error.message).to include('docx')
      expect(error.message).to include('not supported')
    end

    it 'lists available formats' do
      error = described_class.new(:docx, available: %i[html markdown])

      expect(error.message).to include('html')
      expect(error.message).to include('markdown')
    end
  end

  describe '#requested_format' do
    it 'returns the requested format' do
      error = described_class.new(:pdf)

      expect(error.requested_format).to eq(:pdf)
    end
  end

  describe '#available_formats' do
    it 'returns the list of available formats' do
      error = described_class.new(:pdf, available: %i[html md])

      expect(error.available_formats).to eq(%i[html md])
    end
  end
end
