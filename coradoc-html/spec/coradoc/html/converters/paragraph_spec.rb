# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/core_model'

RSpec.describe Coradoc::Html::Converters::Paragraph do
  describe '#to_html' do
    it 'converts a basic paragraph to HTML' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'This is a paragraph.'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p>This is a paragraph.</p>')
    end

    it 'converts paragraph with ID' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        id: 'para1',
        content: 'Paragraph with ID.'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('id="para1"')
      expect(html).to include('Paragraph with ID.')
    end

    it 'converts paragraph with multiple content parts' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        children: ['First part. ', 'Second part.']
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p>First part. Second part.</p>')
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

    it 'handles empty paragraph content' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: ''
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<p></p>')
    end

    it 'converts paragraph with inline formatting' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        children: [
          'Text with ',
          Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold'),
          ' and ',
          Coradoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic')
        ]
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('<strong>bold</strong>')
      expect(html).to include('<em>italic</em>')
    end

    it 'converts paragraph with title' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        title: 'Note',
        content: 'This is important.'
      )

      html = described_class.to_html(paragraph)

      expect(html).to include('This is important.')
    end
  end

  describe '#to_coradoc' do
    it 'converts HTML <p> to CoreModel Block' do
      html = '<p>This is a paragraph.</p>'
      nokogiri_doc = Nokogiri::HTML(html)
      p_element = nokogiri_doc.at_css('p')

      model = described_class.to_coradoc(p_element)

      expect(model).to be_a(Coradoc::CoreModel::Block)
      expect(model.element_type).to eq('paragraph')
      expect(model.children).not_to be_empty
    end

    it 'converts HTML <p> with ID' do
      html = '<p id="para1">Paragraph with ID.</p>'
      nokogiri_doc = Nokogiri::HTML(html)
      p_element = nokogiri_doc.at_css('p')

      model = described_class.to_coradoc(p_element)

      expect(model.id).to eq('para1')
      expect(model.element_type).to eq('paragraph')
    end
  end
end
