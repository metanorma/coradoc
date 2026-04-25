# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ToCoreModel do
  describe '.transform' do
    context 'with Document' do
      it 'transforms an AsciiDoc Document to CoreModel' do
        title_content = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Test Document')
        doc = Coradoc::AsciiDoc::Model::Document.new(
          header: Coradoc::AsciiDoc::Model::Header.new(
            title: Coradoc::AsciiDoc::Model::Title.new(content: [title_content])
          )
        )

        result = described_class.transform(doc)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('document')
      end
    end

    context 'with Section' do
      it 'transforms an AsciiDoc Section to CoreModel' do
        title_content = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Test Section')
        section = Coradoc::AsciiDoc::Model::Section.new(
          title: Coradoc::AsciiDoc::Model::Title.new(content: [title_content]),
          level: 1
        )

        result = described_class.transform(section)

        expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
        expect(result.element_type).to eq('section')
      end
    end

    context 'with Paragraph' do
      it 'transforms an AsciiDoc Paragraph to CoreModel' do
        text = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello world')
        paragraph = Coradoc::AsciiDoc::Model::Paragraph.new(
          content: [text]
        )

        result = described_class.transform(paragraph)

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end

    context 'with Block::Core' do
      it 'transforms a generic Block to CoreModel' do
        block = Coradoc::AsciiDoc::Model::Block::Core.new(
          delimiter_char: '-',
          delimiter_len: 4,
          lines: ['line 1', 'line 2']
        )

        result = described_class.transform(block)

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end

    context 'with Block::Quote' do
      it 'transforms a Quote block to CoreModel' do
        quote = Coradoc::AsciiDoc::Model::Block::Quote.new(
          lines: ['quoted text']
        )

        result = described_class.transform(quote)

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end

    context 'with Block::Example' do
      it 'transforms an Example block to CoreModel' do
        example = Coradoc::AsciiDoc::Model::Block::Example.new(
          lines: ['example content']
        )

        result = described_class.transform(example)

        expect(result).to be_a(Coradoc::CoreModel::Block)
      end
    end

    context 'with List::Unordered' do
      it 'transforms an Unordered list to CoreModel' do
        list = Coradoc::AsciiDoc::Model::List::Unordered.new(
          items: [Coradoc::AsciiDoc::Model::List::Item.new(content: ['Item 1'])]
        )

        result = described_class.transform(list)

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('unordered')
      end
    end

    context 'with List::Ordered' do
      it 'transforms an Ordered list to CoreModel' do
        list = Coradoc::AsciiDoc::Model::List::Ordered.new(
          items: [Coradoc::AsciiDoc::Model::List::Item.new(content: ['Item 1'])]
        )

        result = described_class.transform(list)

        expect(result).to be_a(Coradoc::CoreModel::ListBlock)
        expect(result.marker_type).to eq('ordered')
      end
    end

    context 'with List::Definition' do
      it 'transforms a Definition list to CoreModel' do
        list = Coradoc::AsciiDoc::Model::List::Definition.new(
          items: []
        )

        result = described_class.transform(list)

        expect(result).to be_a(Coradoc::CoreModel::DefinitionList)
      end
    end

    context 'with Admonition' do
      it 'transforms an Admonition to CoreModel' do
        admonition = Coradoc::AsciiDoc::Model::Admonition.new(
          type: 'NOTE',
          content: 'This is important'
        )

        result = described_class.transform(admonition)

        expect(result).to be_a(Coradoc::CoreModel::AnnotationBlock)
      end
    end

    context 'with Term' do
      it 'transforms a Term to CoreModel' do
        term = Coradoc::AsciiDoc::Model::Term.new(
          term: 'API',
          type: 'acronym'
        )

        result = described_class.transform(term)

        expect(result).to be_a(Coradoc::CoreModel::Term)
      end
    end

    context 'with Inline elements' do
      it 'transforms Bold to CoreModel' do
        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')

        result = described_class.transform(bold)

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.format_type).to eq('bold')
      end

      it 'transforms Italic to CoreModel' do
        italic = Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic text')

        result = described_class.transform(italic)

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.format_type).to eq('italic')
      end

      it 'transforms Monospace to CoreModel' do
        mono = Coradoc::AsciiDoc::Model::Inline::Monospace.new(content: 'code')

        result = described_class.transform(mono)

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.format_type).to eq('monospace')
      end

      it 'transforms Link to CoreModel' do
        link = Coradoc::AsciiDoc::Model::Inline::Link.new(
          url: 'https://example.com',
          text: 'Example'
        )

        result = described_class.transform(link)

        expect(result).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.format_type).to eq('link')
      end
    end

    context 'with Array' do
      it 'transforms each element in an array' do
        elements = [
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold'),
          Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic')
        ]

        result = described_class.transform(elements)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::CoreModel::InlineElement)
        expect(result.last).to be_a(Coradoc::CoreModel::InlineElement)
      end
    end

    context 'with Bibliography' do
      it 'transforms an AsciiDoc Bibliography to CoreModel' do
        bib = Coradoc::AsciiDoc::Model::Bibliography.new(
          id: 'norm-refs',
          title: 'Normative References',
          entries: [
            Coradoc::AsciiDoc::Model::BibliographyEntry.new(
              anchor_name: 'ISO712',
              document_id: 'ISO 712',
              ref_text: 'Cereals and cereal products.'
            )
          ]
        )

        result = described_class.transform(bib)

        expect(result).to be_a(Coradoc::CoreModel::Bibliography)
        expect(result.id).to eq('norm-refs')
        expect(result.title).to eq('Normative References')
        expect(result.entries.length).to eq(1)
        expect(result.entries.first).to be_a(Coradoc::CoreModel::BibliographyEntry)
        expect(result.entries.first.anchor_name).to eq('ISO712')
        expect(result.entries.first.document_id).to eq('ISO 712')
      end
    end

    context 'with BibliographyEntry' do
      it 'transforms an AsciiDoc BibliographyEntry to CoreModel' do
        entry = Coradoc::AsciiDoc::Model::BibliographyEntry.new(
          anchor_name: 'ISO712',
          document_id: 'ISO 712',
          ref_text: 'Cereals and cereal products.'
        )

        result = described_class.transform(entry)

        expect(result).to be_a(Coradoc::CoreModel::BibliographyEntry)
        expect(result.anchor_name).to eq('ISO712')
        expect(result.document_id).to eq('ISO 712')
        expect(result.ref_text).to eq('Cereals and cereal products.')
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
      doc = Coradoc::AsciiDoc::Model::Document.new

      result = transformer.transform(doc)

      expect(result).to be_a(Coradoc::CoreModel::StructuralElement)
    end
  end
end
