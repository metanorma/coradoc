# frozen_string_literal: true

require 'spec_helper'
require 'leptris'

RSpec.describe Coradoc::Html::Transform::ToCoreModel do
  describe '.transform' do
    subject(:transform) { described_class.transform(model) }

    context 'with Leptris::XML::Document' do
      let(:model) { Leptris::HTML.parse('<p>Hello</p>') }

      it 'converts to CoreModel elements' do
        result = transform
        expect(result).to be_a(Array)
        expect(result.first).to be_a(Coradoc::CoreModel::Base)
      end
    end

    context 'with Leptris::XML::Node' do
      let(:model) { Leptris::HTML.parse('<h1>Title</h1>').at_css('h1') }

      it 'converts to CoreModel' do
        expect(transform).to be_a(Coradoc::CoreModel::Base)
      end
    end

    context 'with CoreModel::Base' do
      let(:model) do
        Coradoc::CoreModel::ParagraphBlock.new(
          content: 'Already CoreModel'
        )
      end

      it 'returns the model unchanged' do
        expect(transform).to equal(model)
      end
    end

    context 'with Array' do
      let(:model) do
        [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'Para 1'),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'Para 2')
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
