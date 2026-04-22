# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::FromCoreModel do
  describe '.transform' do
    context 'with StructuralElement (document)' do
      it 'transforms a CoreModel document to AsciiDoc Document' do
        core_doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          title: 'Test Document'
        )

        result = described_class.transform(core_doc)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
      end
    end

    context 'with StructuralElement (section)' do
      it 'transforms a CoreModel section to AsciiDoc Section' do
        core_section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Test Section',
          level: 2
        )

        result = described_class.transform(core_section)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Section)
      end
    end

    context 'with Block' do
      it 'transforms a CoreModel Block to AsciiDoc Block' do
        core_block = Coradoc::CoreModel::Block.new(
          delimiter_type: '====',
          content: 'Example content'
        )

        result = described_class.transform(core_block)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Block::Core)
      end
    end

    context 'with AnnotationBlock' do
      it 'transforms a CoreModel AnnotationBlock to AsciiDoc Admonition' do
        core_annotation = Coradoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'NOTE',
          content: 'Important note'
        )

        result = described_class.transform(core_annotation)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Admonition)
      end
    end

    context 'with ListBlock' do
      it 'transforms a CoreModel ListBlock (unordered) to AsciiDoc List' do
        core_list = Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: []
        )

        result = described_class.transform(core_list)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Unordered)
      end

      it 'transforms a CoreModel ListBlock (ordered) to AsciiDoc List' do
        core_list = Coradoc::CoreModel::ListBlock.new(
          marker_type: 'ordered',
          items: []
        )

        result = described_class.transform(core_list)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Ordered)
      end

      it 'transforms a CoreModel ListBlock (definition) to AsciiDoc List' do
        core_list = Coradoc::CoreModel::ListBlock.new(
          marker_type: 'definition',
          items: []
        )

        result = described_class.transform(core_list)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Definition)
      end
    end

    context 'with ListItem' do
      it 'transforms a CoreModel ListItem to AsciiDoc ListItem' do
        core_item = Coradoc::CoreModel::ListItem.new(
          text: 'Item text'
        )

        result = described_class.transform(core_item)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Item)
      end
    end

    context 'with Term' do
      it 'transforms a CoreModel Term to AsciiDoc Term' do
        core_term = Coradoc::CoreModel::Term.new(
          text: 'API',
          type: 'acronym'
        )

        result = described_class.transform(core_term)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Term)
      end
    end

    context 'with InlineElement' do
      it 'transforms bold InlineElement to AsciiDoc Bold' do
        core_inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )

        result = described_class.transform(core_inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Bold)
      end

      it 'transforms italic InlineElement to AsciiDoc Italic' do
        core_inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'italic',
          content: 'italic text'
        )

        result = described_class.transform(core_inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Italic)
      end

      it 'transforms monospace InlineElement to AsciiDoc Monospace' do
        core_inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'monospace',
          content: 'code'
        )

        result = described_class.transform(core_inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Monospace)
      end

      it 'transforms link InlineElement to AsciiDoc Link' do
        core_inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'link',
          content: 'Example',
          target: 'https://example.com'
        )

        result = described_class.transform(core_inline)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Link)
      end
    end

    context 'with Table' do
      it 'transforms a CoreModel Table to AsciiDoc Table' do
        core_table = Coradoc::CoreModel::Table.new(
          rows: []
        )

        result = described_class.transform(core_table)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Table)
      end
    end

    context 'with Image' do
      it 'transforms a CoreModel Image to AsciiDoc Image' do
        core_image = Coradoc::CoreModel::Image.new(
          src: 'test.png',
          alt: 'Test Image'
        )

        result = described_class.transform(core_image)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Image::Core)
      end
    end

    context 'with Array' do
      it 'transforms each element in an array' do
        core_elements = [
          Coradoc::CoreModel::InlineElement.new(format_type: 'bold', content: 'bold'),
          Coradoc::CoreModel::InlineElement.new(format_type: 'italic', content: 'italic')
        ]

        result = described_class.transform(core_elements)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::AsciiDoc::Model::Inline::Bold)
        expect(result.last).to be_a(Coradoc::AsciiDoc::Model::Inline::Italic)
      end
    end

    context 'with unknown type' do
      it 'returns the object unchanged for unknown types' do
        unknown = Object.new

        result = described_class.transform(unknown)

        expect(result).to eq(unknown)
      end
    end
  end

  describe '#transform' do
    it 'instance method delegates to class method' do
      transformer = described_class.new
      core_doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test'
      )

      result = transformer.transform(core_doc)

      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end
end
