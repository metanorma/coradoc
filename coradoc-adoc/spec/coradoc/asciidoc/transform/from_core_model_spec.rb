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

      it 'transforms highlight InlineElement to AsciiDoc Highlight' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'highlight', content: 'marked')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Highlight)
      end

      it 'transforms strikethrough InlineElement to AsciiDoc Strikethrough' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'strikethrough', content: 'deleted')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Strikethrough)
      end

      it 'transforms subscript InlineElement to AsciiDoc Subscript' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'subscript', content: '2')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Subscript)
      end

      it 'transforms superscript InlineElement to AsciiDoc Superscript' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'superscript', content: '2')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Superscript)
      end

      it 'transforms underline InlineElement to AsciiDoc Underline' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'underline', content: 'underlined')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Underline)
      end

      it 'transforms xref InlineElement to AsciiDoc CrossReference' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'xref', target: 'section1', content: 'Section 1')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::CrossReference)
      end

      it 'transforms footnote InlineElement to AsciiDoc Footnote' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'footnote', target: 'fn1', content: 'note text')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Footnote)
      end

      it 'transforms stem InlineElement to AsciiDoc Stem' do
        core_inline = Coradoc::CoreModel::InlineElement.new(format_type: 'stem', content: 'x^2')
        expect(described_class.transform(core_inline)).to be_a(Coradoc::AsciiDoc::Model::Inline::Stem)
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

    context 'with Bibliography' do
      it 'transforms a CoreModel Bibliography to AsciiDoc Bibliography' do
        core_bib = Coradoc::CoreModel::Bibliography.new(
          id: 'norm-refs',
          title: 'Normative References',
          entries: [
            Coradoc::CoreModel::BibliographyEntry.new(
              anchor_name: 'ISO712',
              document_id: 'ISO 712',
              ref_text: 'Cereals and cereal products.'
            )
          ]
        )

        result = described_class.transform(core_bib)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Bibliography)
        expect(result.id).to eq('norm-refs')
        expect(result.title).to eq('Normative References')
        expect(result.entries.length).to eq(1)
        expect(result.entries.first).to be_a(Coradoc::AsciiDoc::Model::BibliographyEntry)
        expect(result.entries.first.anchor_name).to eq('ISO712')
        expect(result.entries.first.document_id).to eq('ISO 712')
        expect(result.entries.first.ref_text).to eq('Cereals and cereal products.')
      end
    end

    context 'with BibliographyEntry' do
      it 'transforms a CoreModel BibliographyEntry to AsciiDoc BibliographyEntry' do
        core_entry = Coradoc::CoreModel::BibliographyEntry.new(
          anchor_name: 'ISO712',
          document_id: 'ISO 712',
          ref_text: 'Cereals and cereal products.'
        )

        result = described_class.transform(core_entry)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::BibliographyEntry)
        expect(result.anchor_name).to eq('ISO712')
        expect(result.document_id).to eq('ISO 712')
        expect(result.ref_text).to eq('Cereals and cereal products.')
      end
    end

    context 'with Footnote' do
      it 'transforms a CoreModel Footnote to AsciiDoc Inline Footnote' do
        core_fn = Coradoc::CoreModel::Footnote.new(id: 'fn1', content: 'Note text')

        result = described_class.transform(core_fn)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Footnote)
        expect(result.id).to eq('fn1')
        expect(result.text).to eq('Note text')
      end
    end

    context 'with FootnoteReference' do
      it 'transforms a CoreModel FootnoteReference to AsciiDoc Inline Footnote' do
        core_ref = Coradoc::CoreModel::FootnoteReference.new(id: 'fn1')

        result = described_class.transform(core_ref)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::Inline::Footnote)
        expect(result.id).to eq('fn1')
      end
    end

    context 'with Abbreviation' do
      it 'transforms a CoreModel Abbreviation to AsciiDoc TextElement' do
        core_abbr = Coradoc::CoreModel::Abbreviation.new(term: 'API', definition: 'Application Programming Interface')

        result = described_class.transform(core_abbr)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::TextElement)
        expect(result.content).to include('API')
        expect(result.content).to include('Application Programming Interface')
      end
    end

    context 'with DefinitionList' do
      it 'transforms a CoreModel DefinitionList to AsciiDoc List::Definition' do
        core_dl = Coradoc::CoreModel::DefinitionList.new(
          items: [
            Coradoc::CoreModel::DefinitionItem.new(term: 'Foo', definitions: ['Bar'])
          ]
        )

        result = described_class.transform(core_dl)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::List::Definition)
        expect(result.items.length).to eq(1)
        expect(result.items.first).to be_a(Coradoc::AsciiDoc::Model::List::DefinitionItem)
      end
    end

    context 'with Toc' do
      it 'transforms a CoreModel Toc to AsciiDoc TextElement placeholder' do
        core_toc = Coradoc::CoreModel::Toc.new

        result = described_class.transform(core_toc)

        expect(result).to be_a(Coradoc::AsciiDoc::Model::TextElement)
        expect(result.content).to include('toc')
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
