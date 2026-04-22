# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/core_model'

RSpec.describe Coradoc::Html::Converters::Paragraph do
  describe '#to_html - Paragraph Conversion' do
    # CoreModel::Block with element_type "paragraph" should convert to HTML <p>

    it 'converts a basic paragraph to HTML' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'This is a paragraph.'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p>This is a paragraph.</p>')
    end

    it 'converts paragraph with multi-line content' do
      # In CoreModel, content is already normalized (lines joined with spaces)
      # by the ToCoreModel transformer
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Line 1 Line 2 Line 3'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p>Line 1 Line 2 Line 3</p>')
    end

    it 'converts paragraph with ID' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        id: 'my-paragraph',
        content: 'Content here'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('id="my-paragraph"')
      expect(html).to include('<p')
      expect(html).to include('Content here')
    end

    it 'escapes HTML in paragraph content' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: "<script>alert('xss')</script>"
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('&lt;script&gt;')
      expect(html).not_to include('<script>')
    end

    it 'handles empty paragraph' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: ''
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p></p>')
    end

    it 'handles paragraph with inline elements' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        children: [
          'Text with ',
          Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold'),
          ' text'
        ]
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p>Text with <strong>bold</strong> text</p>')
    end

    it 'handles paragraph with link' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        children: [
          'Visit ',
          Coradoc::CoreModel::InlineElement.new(
            format_type: 'link',
            content: 'example.com',
            target: 'https://example.com'
          )
        ]
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<a href="https://example.com">example.com</a>')
    end
  end
end
