# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Transform::ToCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(model) }

    context 'with CoreModel::Base' do
      let(:model) do
        Coradoc::CoreModel::Block.new(
          element_type: 'paragraph',
          content: 'Already CoreModel'
        )
      end

      it 'returns the model unchanged' do
        expect(transform).to eq(model)
      end
    end

    context 'with Array' do
      let(:model) do
        [
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 1'),
          Coradoc::CoreModel::Block.new(element_type: 'paragraph', content: 'Para 2')
        ]
      end

      it 'transforms each element' do
        expect(transform).to be_an(Array)
        expect(transform.length).to eq(2)
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
