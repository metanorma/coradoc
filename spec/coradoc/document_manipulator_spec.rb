# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::DocumentManipulator do
  let(:document) do
    Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      title: 'Test Document',
      children: [
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Introduction',
          level: 1,
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'This is the introduction.'
            )
          ]
        ),
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Background',
          level: 2,
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'Background information.'
            )
          ]
        )
      ]
    )
  end

  let(:manipulator) { described_class.new(document) }

  describe '.new' do
    it 'accepts a CoreModel document' do
      expect(manipulator.document).to eq(document)
    end

    it 'raises error for non-CoreModel input' do
      expect { described_class.new('not a document') }.to raise_error(ArgumentError)
    end
  end

  describe '#query' do
    it 'queries elements using CSS-like selectors' do
      results = manipulator.query('section')
      expect(results).to be_an(Array)
    end
  end

  describe '#transform_text' do
    it 'transforms text content' do
      manipulator.transform_text(&:upcase)
      expect(document.children.first.children.first.content).to eq('THIS IS THE INTRODUCTION.')
    end

    it 'returns self for chaining' do
      result = manipulator.transform_text(&:upcase)
      expect(result).to eq(manipulator)
    end
  end

  describe '#transform_headings' do
    it 'transforms heading text' do
      manipulator.transform_headings(&:upcase)
      expect(document.children.first.title).to eq('INTRODUCTION')
    end

    it 'returns self for chaining' do
      result = manipulator.transform_headings(&:upcase)
      expect(result).to eq(manipulator)
    end
  end

  describe '#add_metadata' do
    it 'adds metadata to document' do
      manipulator.add_metadata('author' => 'Test Author')
      expect(document.metadata('author')).to eq('Test Author')
    end

    it 'returns self for chaining' do
      result = manipulator.add_metadata('key' => 'value')
      expect(result).to eq(manipulator)
    end
  end

  describe '#set_title' do
    it 'sets document title' do
      manipulator.set_title('New Title')
      expect(document.title).to eq('New Title')
    end

    it 'returns self for chaining' do
      result = manipulator.set_title('New Title')
      expect(result).to eq(manipulator)
    end
  end

  describe '#set_id' do
    it 'sets document id' do
      manipulator.set_id('new-id')
      expect(document.id).to eq('new-id')
    end

    it 'returns self for chaining' do
      result = manipulator.set_id('new-id')
      expect(result).to eq(manipulator)
    end
  end

  describe '#to_core' do
    it 'returns the underlying document' do
      expect(manipulator.to_core).to eq(document)
    end
  end

  describe '#clone' do
    it 'creates a new manipulator with cloned document' do
      cloned = manipulator.clone
      expect(cloned).not_to eq(manipulator)
      expect(cloned.document).not_to be(document) # Different object
    end

    it "modifications to clone don't affect original" do
      cloned = manipulator.clone
      cloned.set_title('Cloned Title')
      expect(document.title).to eq('Test Document')
      expect(cloned.document.title).to eq('Cloned Title')
    end
  end

  describe '#remove_elements' do
    let(:doc_with_comments) do
      Coradoc::CoreModel::StructuralElement.new(
        element_type: 'document',
        children: [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Keep this'),
          Coradoc::CoreModel::Block.new(element_type: 'comment', content: 'Remove this'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Keep this too')
        ]
      )
    end

    it 'removes elements by type' do
      m = described_class.new(doc_with_comments)
      m.remove_elements(:comment)

      types = doc_with_comments.children.map(&:element_type)
      expect(types).not_to include('comment')
      expect(types).to include('paragraph')
    end

    it 'returns self for chaining' do
      m = described_class.new(doc_with_comments)
      expect(m.remove_elements(:comment)).to eq(m)
    end
  end

  describe '#select_sections' do
    it 'filters sections by level' do
      filtered = manipulator.select_sections(level: 1)
      sections = filtered.document.children
      expect(sections.length).to eq(1)
      expect(sections.first.title).to eq('Introduction')
    end

    it 'filters sections by title' do
      filtered = manipulator.select_sections(title: 'Background')
      sections = filtered.document.children
      expect(sections.length).to eq(1)
      expect(sections.first.title).to eq('Background')
    end
  end

  describe '#to_html' do
    it 'serializes to HTML' do
      html = manipulator.to_html
      expect(html).to include('Test Document')
    end
  end

  describe '#to' do
    it 'serializes to specified format' do
      html = manipulator.to(:html)
      expect(html).to include('Test Document')
    end
  end

  describe 'chaining' do
    it 'supports method chaining' do
      result = manipulator
               .transform_text(&:upcase)
               .transform_headings(&:upcase)
               .add_metadata('processed' => 'true')
               .set_title('Processed Document')

      expect(result).to be_a(described_class)
      expect(document.title).to eq('Processed Document')
      expect(document.metadata('processed')).to eq('true')
    end
  end
end

RSpec.describe 'Coradoc.manipulate' do
  it 'creates a DocumentManipulator' do
    doc = Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      title: 'Test'
    )

    manipulator = Coradoc.manipulate(doc)
    expect(manipulator).to be_a(Coradoc::DocumentManipulator)
  end
end
