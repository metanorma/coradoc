# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/core_model'

RSpec.describe Coradoc::Html::Converters::Section do
  describe '#to_html' do
    it 'converts a basic section to HTML' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'This is a paragraph.'
      )

      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Test Section',
        children: [paragraph]
      )

      html = described_class.to_html(section)

      expect(html).to include('<h2>Test Section</h2>')
      expect(html).to include('<p>This is a paragraph.</p>')
    end

    it 'converts section with ID' do
      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Section',
        id: 'section1'
      )

      html = described_class.to_html(section)

      expect(html).to include('<h2 id="section1">Section</h2>')
    end

    it 'converts nested sections' do
      child_section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 2,
        title: 'Child'
      )

      parent_section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Parent',
        children: [child_section]
      )

      html = described_class.to_html(parent_section)

      expect(html).to include('<h2>Parent</h2>')
      expect(html).to include('<h3>Child</h3>')
    end

    it 'handles empty section content' do
      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Empty Section'
      )

      html = described_class.to_html(section)

      expect(html).to include('<h2>Empty Section</h2>')
    end

    it 'escapes HTML in section content' do
      paragraph = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: "<script>alert('xss')</script>"
      )

      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'XSS Test',
        children: [paragraph]
      )

      html = described_class.to_html(section)

      expect(html).to include('&lt;script&gt;')
      expect(html).not_to include('<script>')
    end

    it 'converts section with lists' do
      list_item = Coradoc::CoreModel::ListItem.new(
        content: 'Item 1'
      )

      list = Coradoc::CoreModel::ListBlock.new(
        marker_type: 'unordered',
        items: [list_item]
      )

      section = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Section with List',
        children: [list]
      )

      html = described_class.to_html(section)

      expect(html).to include('<h2>Section with List</h2>')
      expect(html).to include('<ul>')
      expect(html).to include('<li>Item 1</li>')
      expect(html).to include('</ul>')
    end
  end
end
