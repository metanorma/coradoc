# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/footnote_drop'

RSpec.describe Coradoc::Html::Drop::FootnoteDrop do
  describe 'with Footnote model' do
    let(:model) { CoreModel::Footnote.new(id: 'fn1', content: [CoreModel::TextContent.new(text: 'A footnote.')]) }
    let(:drop) { described_class.new(model) }

    it_behaves_like 'a liquid drop'

    describe '#footnote_id' do
      it 'returns the footnote id' do
        expect(drop.footnote_id).to eq('fn1')
      end
    end

    describe '#content' do
      it 'returns escaped content' do
        expect(drop.content).to eq('A footnote.')
      end
    end

    describe '#inline?' do
      it 'returns false when id is present' do
        expect(drop.inline?).to be false
      end

      it 'returns true when id is empty' do
        fn = CoreModel::Footnote.new(id: '', content: [CoreModel::TextContent.new(text: 'inline')])
        expect(described_class.new(fn).inline?).to be true
      end
    end
  end

  describe 'with FootnoteReference model' do
    let(:model) { CoreModel::FootnoteReference.new(id: 'fn1') }
    let(:drop) { described_class.new(model) }

    it 'maps FootnoteReference to FootnoteDrop via DropFactory' do
      drop = Coradoc::Html::Drop::DropFactory.create(model)
      expect(drop).to be_a(described_class)
    end

    describe '#footnote_id' do
      it 'returns the reference id' do
        expect(drop.footnote_id).to eq('fn1')
      end
    end
  end
end
