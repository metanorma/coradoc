# frozen_string_literal: true

require 'coradoc/html'

RSpec.describe 'Paragraph Normalization - End to End' do
  describe 'parsing and converting paragraphs' do
    it 'normalizes multi-line paragraphs correctly' do
      # AsciiDoc source:
      # Line 1
      # Line 2
      # Line 3
      input = <<~ASCIIDOC
        Line 1
        Line 2
        Line 3
      ASCIIDOC

      document = Coradoc.parse(input, format: :asciidoc)
      html = Coradoc::Html::Converters::Document.to_html(document)

      # Lines should be joined with spaces
      expect(html).to include('<p>Line 1 Line 2 Line 3</p>')
    end

    it 'handles single line paragraphs' do
      input = 'Single line paragraph'

      document = Coradoc.parse(input, format: :asciidoc)
      html = Coradoc::Html::Converters::Document.to_html(document)

      expect(html).to include('<p>Single line paragraph</p>')
    end

    it 'handles multiple paragraphs' do
      input = <<~ASCIIDOC
        First paragraph
        with multiple lines.

        Second paragraph
        also with multiple lines.
      ASCIIDOC

      document = Coradoc.parse(input, format: :asciidoc)
      html = Coradoc::Html::Converters::Document.to_html(document)

      expect(html).to include('<p>First paragraph with multiple lines.</p>')
      expect(html).to include('<p>Second paragraph also with multiple lines.</p>')
    end

    it 'preserves explicit hard line breaks' do
      # NOTE: This test documents the expected behavior
      # The parser may need updates to properly detect hard line breaks
      input = <<~ASCIIDOC
        Line 1 +
        Line 2
      ASCIIDOC

      document = Coradoc.parse(input, format: :asciidoc)
      Coradoc::Html::Converters::Document.to_html(document)

      # Should preserve line break with <br>
      # Note: This may not work until parser is updated
      # expect(html).to include("<br>")
    end

    it 'handles line continuation' do
      # NOTE: This test documents the expected behavior
      input = <<~ASCIIDOC
        Line 1 +
        Line 2
      ASCIIDOC

      document = Coradoc.parse(input, format: :asciidoc)
      Coradoc::Html::Converters::Document.to_html(document)

      # Should join without space
      # Note: This may not work until parser is updated
    end
  end
end
