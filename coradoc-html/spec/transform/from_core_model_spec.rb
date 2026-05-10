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

      it 'returns HTML string' do
        expect(transform).to be_a(String)
        expect(transform).to include('<html')
      end
    end

    context 'with CoreModel::Block' do
      let(:model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Paragraph content'
        )
      end

      it 'returns HTML string' do
        expect(transform).to be_a(String)
        expect(transform).to include('<')
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

      it 'returns HTML string' do
        expect(transform).to be_a(String)
        expect(transform).to include('<')
      end
    end

    context 'with Array' do
      let(:model) do
        [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 1')
        ]
      end

      it 'joins transformed elements' do
        expect(transform).to be_a(String)
      end
    end

    context 'with unknown type' do
      let(:model) { 'plain string' }

      it 'returns the value as string' do
        expect(transform).to eq('plain string')
      end
    end
  end
end
