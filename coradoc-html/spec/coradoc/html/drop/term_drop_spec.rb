# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/term_drop'

RSpec.describe Coradoc::Html::Drop::TermDrop do
  let(:model) { CoreModel::Term.new(text: 'concept') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#text' do
    it 'returns escaped text' do
      expect(drop.text).to eq('concept')
    end
  end

  describe '#term_ref' do
    it 'returns the raw text reference' do
      expect(drop.term_ref).to eq('concept')
    end
  end

  describe '#css_class' do
    it 'returns term class' do
      expect(drop.css_class).to include('term')
    end
  end
end
