# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/visitor'

RSpec.describe Coradoc::Visitor do
  let(:document) do
    Coradoc::CoreModel::StructuralElement.new(
      element_type: 'document',
      title: 'Test Document',
      children: [
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'First paragraph'
        ),
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          title: 'Section 1',
          children: [
            Coradoc::CoreModel::Block.new(
              element_type: 'paragraph',
              content: 'Second paragraph'
            )
          ]
        ),
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'Item 1'),
            Coradoc::CoreModel::ListItem.new(content: 'Item 2')
          ]
        )
      ]
    )
  end

  describe Coradoc::Visitor::Base do
    subject { described_class.new }

    describe '#visit' do
      it 'visits structural elements' do
        expect { subject.visit(document) }.not_to raise_error
      end

      it 'visits blocks' do
        block = Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Test')
        expect { subject.visit(block) }.not_to raise_error
      end

      it 'visits list blocks' do
        list = Coradoc::CoreModel::ListBlock.new(marker_type: 'unordered')
        expect { subject.visit(list) }.not_to raise_error
      end

      it 'visits nil without error' do
        expect { subject.visit(nil) }.not_to raise_error
      end

      it 'visits arrays' do
        arr = [document, Coradoc::CoreModel::Block.new(element_type: 'test')]
        expect { subject.visit(arr) }.not_to raise_error
      end
    end
  end

  describe Coradoc::Visitor::Collector do
    describe '#visit' do
      it 'collects all elements when no types specified' do
        collector = described_class.new
        document.accept(collector)

        expect(collector.items.length).to be > 0
        expect(collector.items).to include(document)
      end

      it 'collects only specified types' do
        collector = described_class.new(Coradoc::CoreModel::Block)
        document.accept(collector)

        expect(collector.items).to all(be_a(Coradoc::CoreModel::Block))
      end

      it 'collects multiple types' do
        collector = described_class.new(
          Coradoc::CoreModel::Block,
          Coradoc::CoreModel::ListBlock
        )
        document.accept(collector)

        expect(collector.items).to all(be_a(Coradoc::CoreModel::Block).or(be_a(Coradoc::CoreModel::ListBlock)))
      end
    end

    describe '#match?' do
      it 'returns true for all when no types specified' do
        collector = described_class.new
        expect(collector.match?(document)).to be true
        expect(collector.match?(Coradoc::CoreModel::Block.new)).to be true
      end

      it 'returns true for matching types' do
        collector = described_class.new(Coradoc::CoreModel::Block)
        expect(collector.match?(Coradoc::CoreModel::Block.new)).to be true
        expect(collector.match?(Coradoc::CoreModel::ListBlock.new)).to be false
      end
    end
  end

  describe Coradoc::Visitor::Transformer do
    describe '#visit' do
      it 'transforms elements using the block' do
        transformed = []
        transformer = described_class.new do |element|
          transformed << element.class
        end

        document.accept(transformer)

        expect(transformed).to include(Coradoc::CoreModel::StructuralElement)
        expect(transformed).to include(Coradoc::CoreModel::Block)
      end

      it 'can modify elements' do
        transformer = described_class.new do |element|
          if element.is_a?(Coradoc::CoreModel::Block) && element.content.is_a?(String)
            element.content = element.content.upcase
          end
        end

        document.accept(transformer)

        paragraphs = document.children.select { |c| c.is_a?(Coradoc::CoreModel::Block) }
        first_paragraph = paragraphs.first
        expect(first_paragraph.content).to eq('FIRST PARAGRAPH')
      end
    end
  end

  describe Coradoc::Visitor::Finder do
    describe '#visit' do
      it 'finds elements matching predicate' do
        finder = described_class.new { |e| e.is_a?(Coradoc::CoreModel::Block) }
        document.accept(finder)

        expect(finder.results).to all(be_a(Coradoc::CoreModel::Block))
      end

      it 'finds elements by id' do
        block_with_id = Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Test',
          id: 'my-block'
        )
        doc = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          children: [block_with_id]
        )

        finder = described_class.new { |e| e.id == 'my-block' }
        doc.accept(finder)

        expect(finder.first).to eq(block_with_id)
      end
    end

    describe '#first' do
      it 'returns first matching result' do
        finder = described_class.new { |e| e.is_a?(Coradoc::CoreModel::ListItem) }
        document.accept(finder)

        expect(finder.first).to be_a(Coradoc::CoreModel::ListItem)
      end

      it 'returns nil when no matches' do
        finder = described_class.new { |e| e.id == 'nonexistent' }
        document.accept(finder)

        expect(finder.first).to be_nil
      end
    end

    describe '#all' do
      it 'returns all matching results' do
        finder = described_class.new { |e| e.is_a?(Coradoc::CoreModel::Block) }
        document.accept(finder)

        expect(finder.all.length).to be >= 2
      end
    end
  end

  describe 'Document#accept' do
    it 'allows visitor pattern on CoreModel elements' do
      word_count = 0
      visitor = Coradoc::Visitor::Transformer.new do |element|
        if element.is_a?(Coradoc::CoreModel::Block) && element.content.is_a?(String)
          word_count += element.content.split.length
        end
      end

      document.accept(visitor)

      expect(word_count).to eq(4) # "First paragraph" (2) + "Second paragraph" (2)
    end
  end

  describe 'Table visitor' do
    let(:table) do
      Coradoc::CoreModel::Table.new(
        rows: [
          Coradoc::CoreModel::TableRow.new(
            cells: [
              Coradoc::CoreModel::TableCell.new(content: 'A1'),
              Coradoc::CoreModel::TableCell.new(content: 'B1')
            ]
          ),
          Coradoc::CoreModel::TableRow.new(
            cells: [
              Coradoc::CoreModel::TableCell.new(content: 'A2'),
              Coradoc::CoreModel::TableCell.new(content: 'B2')
            ]
          )
        ]
      )
    end

    it 'visits table structure' do
      cells = []
      visitor = Coradoc::Visitor::Transformer.new do |element|
        cells << element if element.is_a?(Coradoc::CoreModel::TableCell)
      end

      table.accept(visitor)

      expect(cells.length).to eq(4)
    end
  end

  describe 'Image visitor' do
    let(:image) do
      Coradoc::CoreModel::Image.new(
        src: 'test.png',
        alt: 'Test image'
      )
    end

    it 'visits image elements' do
      visited = []
      visitor = Coradoc::Visitor::Transformer.new do |element|
        visited << element if element.is_a?(Coradoc::CoreModel::Image)
      end

      image.accept(visitor)

      expect(visited).to include(image)
    end
  end

  describe 'Annotation block visitor' do
    let(:admonition) do
      Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'note',
        content: 'This is a note'
      )
    end

    it 'visits annotation blocks' do
      visited = []
      visitor = Coradoc::Visitor::Transformer.new do |element|
        visited << element if element.is_a?(Coradoc::CoreModel::AnnotationBlock)
      end

      admonition.accept(visitor)

      expect(visited).to include(admonition)
    end
  end
end
