# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Normalize do
  describe '.normalize' do
    context 'with StructuralElement' do
      it 'normalizes a document' do
        doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          title: 'Test Document',
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'Hello world'
            )
          ]
        )

        result = described_class.normalize(doc)

        # Uses lutaml-model's to_hash with string keys
        expect(result).to be_a(Hash)
        expect(result['element_type']).to eq('document')
        expect(result['title']).to eq('Test Document')
        expect(result['children']).to be_an(Array)
        expect(result['children'].length).to eq(1)
        # _type field distinguishes CoreModel types
        expect(result['_type']).to eq('StructuralElement')
      end

      it 'normalizes a section with level' do
        section = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Section Title',
          level: 2,
          id: 'section-title'
        )

        result = described_class.normalize(section)

        expect(result['element_type']).to eq('section')
        expect(result['level']).to eq(2)
        expect(result['id']).to eq('section-title')
      end
    end

    context 'with Block' do
      it 'normalizes a paragraph block' do
        block = Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Paragraph content'
        )

        result = described_class.normalize(block)

        expect(result).to be_a(Hash)
        expect(result['element_type']).to eq('paragraph')
        expect(result['content']).to eq('Paragraph content')
        expect(result['_type']).to eq('Block')
      end

      it 'normalizes a code block with language' do
        block = Coradoc::CoreModel::Block.new(
          element_type: 'code_block',
          delimiter_type: '----',
          content: 'def hello; end',
          language: 'ruby'
        )

        result = described_class.normalize(block)

        expect(result['language']).to eq('ruby')
        expect(result['element_type']).to eq('code_block')
      end

      it 'normalizes block with id and title' do
        block = Coradoc::CoreModel::Block.new(
          element_type: 'example',
          content: 'Example content',
          id: 'example-1',
          title: 'Example Title'
        )

        result = described_class.normalize(block)

        expect(result['id']).to eq('example-1')
        expect(result['title']).to eq('Example Title')
      end
    end

    context 'with InlineElement' do
      it 'normalizes bold text' do
        inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'bold',
          content: 'bold text'
        )

        result = described_class.normalize(inline)

        expect(result['format_type']).to eq('bold')
        expect(result['content']).to eq('bold text')
        expect(result['_type']).to eq('InlineElement')
      end

      it 'normalizes a link' do
        inline = Coradoc::CoreModel::InlineElement.new(
          format_type: 'link',
          content: 'Click here',
          target: 'https://example.com'
        )

        result = described_class.normalize(inline)

        expect(result['target']).to eq('https://example.com')
      end
    end

    context 'with ListBlock' do
      it 'normalizes an unordered list' do
        list = Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'Item 1'),
            Coradoc::CoreModel::ListItem.new(content: 'Item 2')
          ]
        )

        result = described_class.normalize(list)

        expect(result['marker_type']).to eq('unordered')
        expect(result['items']).to be_an(Array)
        expect(result['_type']).to eq('ListBlock')
      end
    end

    context 'with Table' do
      it 'normalizes a table' do
        table = Coradoc::CoreModel::Table.new(
          rows: [
            Coradoc::CoreModel::TableRow.new(
              cells: [
                Coradoc::CoreModel::TableCell.new(content: 'Cell 1'),
                Coradoc::CoreModel::TableCell.new(content: 'Cell 2')
              ]
            )
          ],
          frame: 'all',
          grid: 'all'
        )

        result = described_class.normalize(table)

        expect(result['frame']).to eq('all')
        expect(result['grid']).to eq('all')
        expect(result['_type']).to eq('Table')
      end
    end

    context 'with Image' do
      it 'normalizes an image' do
        image = Coradoc::CoreModel::Image.new(
          src: 'image.png',
          alt: 'An image',
          caption: 'Figure 1'
        )

        result = described_class.normalize(image)

        expect(result['src']).to eq('image.png')
        expect(result['alt']).to eq('An image')
        expect(result['caption']).to eq('Figure 1')
        expect(result['_type']).to eq('Image')
      end
    end

    context 'with Term' do
      it 'normalizes a term' do
        term = Coradoc::CoreModel::Term.new(
          text: 'Definition term',
          type: 'preferred',
          lang: 'en'
        )

        result = described_class.normalize(term)

        expect(result['text']).to eq('Definition term')
        expect(result['type']).to eq('preferred')
        expect(result['lang']).to eq('en')
        expect(result['_type']).to eq('Term')
      end
    end

    context 'with AnnotationBlock' do
      it 'normalizes an admonition' do
        admonition = Coradoc::CoreModel::AnnotationBlock.new(
          annotation_type: 'note',
          title: 'Important',
          content: 'This is important'
        )

        result = described_class.normalize(admonition)

        expect(result['annotation_type']).to eq('note')
        expect(result['_type']).to eq('AnnotationBlock')
      end
    end

    context 'with arrays' do
      it 'normalizes arrays of elements' do
        arr = [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 1'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 2')
        ]

        result = described_class.normalize(arr)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0]['_type']).to eq('Block')
        expect(result[1]['_type']).to eq('Block')
      end
    end

    context 'with strings' do
      it 'normalizes strings' do
        expect(described_class.normalize('Hello')).to eq('Hello')
        expect(described_class.normalize("Line1\r\nLine2")).to eq("Line1\nLine2")
      end

      it 'normalizes whitespace when option is set' do
        result = described_class.normalize('  multiple   spaces  ', normalize_whitespace: true)
        expect(result).to eq('multiple spaces')
      end
    end

    context 'with nil' do
      it 'returns nil for nil input' do
        expect(described_class.normalize(nil)).to be_nil
      end
    end

    context 'with Hash' do
      it 'normalizes hash values' do
        hash = { 'key' => 'value', 'nested' => { 'inner' => 'data' } }
        result = described_class.normalize(hash)

        expect(result['key']).to eq('value')
        expect(result['nested']['inner']).to eq('data')
      end
    end
  end

  describe '.documents_equal?' do
    it 'returns true for identical documents' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test',
        children: []
      )

      expect(described_class.documents_equal?(doc, doc)).to be true
    end

    it 'returns true for semantically equal documents' do
      doc1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Content')
        ]
      )

      doc2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Content')
        ]
      )

      expect(described_class.documents_equal?(doc1, doc2)).to be true
    end

    it 'returns false for different documents' do
      doc1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test 1',
        children: []
      )

      doc2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test 2',
        children: []
      )

      expect(described_class.documents_equal?(doc1, doc2)).to be false
    end
  end

  describe '.fingerprint' do
    it 'generates consistent fingerprints for identical documents' do
      doc = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test',
        children: []
      )

      fp1 = described_class.fingerprint(doc)
      fp2 = described_class.fingerprint(doc)

      expect(fp1).to eq(fp2)
      expect(fp1.length).to eq(64) # SHA256 hex length
    end

    it 'generates different fingerprints for different documents' do
      doc1 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test 1',
        children: []
      )

      doc2 = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        title: 'Test 2',
        children: []
      )

      expect(described_class.fingerprint(doc1)).not_to eq(described_class.fingerprint(doc2))
    end
  end

  describe Coradoc::Normalize::DiffReporter do
    let(:reporter) { described_class.new }

    describe '#compare' do
      it 'reports no differences for identical documents' do
        doc = { 'type' => 'document', 'title' => 'Test' }
        expect(reporter.compare(doc, doc)).to be_empty
      end

      it 'reports type mismatches' do
        val1 = { 'key' => 'string' }
        val2 = { 'key' => 123 }

        diffs = reporter.compare(val1, val2)

        expect(diffs.length).to eq(1)
        expect(diffs[0][:type]).to eq(:type_mismatch)
        expect(diffs[0][:path]).to eq('key')
      end

      it 'reports value mismatches' do
        val1 = { 'title' => 'Title 1' }
        val2 = { 'title' => 'Title 2' }

        diffs = reporter.compare(val1, val2)

        expect(diffs.length).to eq(1)
        expect(diffs[0][:type]).to eq(:value_mismatch)
      end

      it 'reports missing keys' do
        val1 = { 'a' => 1 }
        val2 = { 'a' => 1, 'b' => 2 }

        diffs = reporter.compare(val1, val2)

        expect(diffs.length).to eq(1)
        expect(diffs[0][:type]).to eq(:missing_key)
      end

      it 'reports extra keys' do
        val1 = { 'a' => 1, 'b' => 2 }
        val2 = { 'a' => 1 }

        diffs = reporter.compare(val1, val2)

        expect(diffs.length).to eq(1)
        expect(diffs[0][:type]).to eq(:extra_key)
      end

      it 'reports array length mismatches' do
        val1 = [1, 2, 3]
        val2 = [1, 2]

        diffs = reporter.compare(val1, val2)

        expect(diffs.any? { |d| d[:type] == :length_mismatch }).to be true
      end

      it 'compares nested structures' do
        val1 = { 'children' => [{ 'type' => 'a' }, { 'type' => 'b' }] }
        val2 = { 'children' => [{ 'type' => 'a' }, { 'type' => 'c' }] }

        diffs = reporter.compare(val1, val2)

        expect(diffs.length).to eq(1)
        expect(diffs[0][:path]).to eq('children[1].type')
      end
    end

    describe '#equal?' do
      it 'returns true when no differences' do
        doc = { 'type' => 'document' }
        reporter.compare(doc, doc)
        expect(reporter.equal?).to be true
      end

      it 'returns false when differences exist' do
        reporter.compare({ 'a' => 1 }, { 'a' => 2 })
        expect(reporter.equal?).to be false
      end
    end
  end
end
