# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/raw_inline_element_drop'

RSpec.describe Coradoc::Html::Drop::RawInlineElementDrop do
  let(:content) { '<abbr title="x">WYSIWYM</abbr>' }
  let(:model)   { CoreModel::RawInlineElement.new(content: content) }
  let(:drop)    { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#template_type' do
    it 'routes to inline_element so the shared template renders it' do
      expect(drop.template_type).to eq('inline_element')
    end
  end

  describe '#text' do
    it 'returns the raw content unescaped' do
      expect(drop.text).to eq('<abbr title="x">WYSIWYM</abbr>')
    end
  end

  describe '#format_type' do
    it 'returns raw_inline' do
      expect(drop.format_type).to eq('raw_inline')
    end
  end

  describe 'DropFactory dispatch' do
    it 'prefers RawInlineElementDrop over InlineElementDrop' do
      resolved = Coradoc::Html::Drop::DropFactory.drop_class_for(model)
      expect(resolved).to be(described_class)
    end
  end
end
