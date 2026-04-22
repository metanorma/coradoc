# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Transform::FromCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(model) }

    context 'with CoreModel::StructuralElement' do
      let(:model) do
        Coradoc::CoreModel::StructuralElement.new(
          element_type: 'document',
          title: 'Test Document',
          children: []
        )
      end

      it 'returns the model for HTML rendering' do
        expect(transform).to eq(model)
        expect(transform.element_type).to eq('document')
      end
    end

    context 'with CoreModel::Block' do
      let(:model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Paragraph content'
        )
      end

      it 'returns the model for HTML rendering' do
        expect(transform).to eq(model)
        expect(transform.element_type).to eq('paragraph')
      end
    end

    context 'with CoreModel::ListBlock' do
      let(:model) do
        Coradoc::CoreModel::ListBlock.new(
          marker_type: 'unordered',
          items: [
            Coradoc::CoreModel::ListItem.new(content: 'Item 1', marker: '*')
          ]
        )
      end

      it 'returns the model for HTML rendering' do
        expect(transform).to eq(model)
        expect(transform.marker_type).to eq('unordered')
      end
    end

    context 'with Array' do
      let(:model) do
        [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 1')
        ]
      end

      it 'transforms each element' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(1)
      end
    end

    context 'with unknown type' do
      let(:model) { 'plain string' }

      it 'returns the value unchanged' do
        expect(transform).to eq('plain string')
      end
    end
  end
end
