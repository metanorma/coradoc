# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Transform::Base do
  # Create a concrete test transformer
  let(:test_transformer_class) do
    Class.new(described_class) do
      def transform(document)
        case document
        when Coradoc::CoreModel::StructuralElement
          transform_structural_element(document)
        when Coradoc::CoreModel::AnnotationBlock
          transform_block(document)
        when Coradoc::CoreModel::Block
          transform_block(document)
        when Array
          transform_collection(document)
        else
          document
        end
      end

      private

      def transform_structural_element(element)
        element.class.new(
          element_type: element.element_type,
          level: element.level,
          title: "Transformed: #{element.title}"
        )
      end

      def transform_block(block)
        block.class.new(
          delimiter_type: block.delimiter_type,
          content: "Transformed: #{block.content}"
        )
      end
    end
  end

  let(:transformer) { test_transformer_class.new }

  describe '#transform' do
    it 'raises NotImplementedError in base class' do
      base_transformer = described_class.new

      expect do
        base_transformer.transform(Object.new)
      end.to raise_error(NotImplementedError, /Subclasses must implement/)
    end

    it 'transforms a document when implemented in subclass' do
      element = Coradoc::CoreModel::StructuralElement.new(
        element_type: 'section',
        level: 1,
        title: 'Introduction'
      )

      result = transformer.transform(element)

      expect(result.title).to eq('Transformed: Introduction')
    end
  end

  describe '#transform_collection' do
    it 'transforms an array of elements' do
      elements = [
        Coradoc::CoreModel::StructuralElement.new(element_type: 'section', level: 1, title: 'A'),
        Coradoc::CoreModel::StructuralElement.new(element_type: 'section', level: 1, title: 'B')
      ]

      results = transformer.transform_collection(elements)

      expect(results).to be_an(Array)
      expect(results.first.title).to eq('Transformed: A')
      expect(results.last.title).to eq('Transformed: B')
    end

    it 'returns empty array for nil input' do
      expect(transformer.transform_collection(nil)).to eq([])
    end
  end

  describe '#core_model?' do
    it 'returns true for CoreModel::Base instances' do
      element = Coradoc::CoreModel::Block.new

      expect(transformer.core_model?(element)).to be true
    end

    it 'returns false for non-CoreModel objects' do
      expect(transformer.core_model?(Object.new)).to be false
      expect(transformer.core_model?('string')).to be false
      expect(transformer.core_model?(123)).to be false
    end
  end

  describe '#element_type' do
    it 'returns element_type for StructuralElement' do
      element = Coradoc::CoreModel::StructuralElement.new(element_type: 'section')

      expect(transformer.element_type(element)).to eq('section')
    end

    it 'returns class name for CoreModel::Base without element_type' do
      element = Coradoc::CoreModel::Block.new

      expect(transformer.element_type(element)).to eq('block')
    end

    it 'returns nil for non-CoreModel objects' do
      expect(transformer.element_type(Object.new)).to be_nil
    end
  end
end
