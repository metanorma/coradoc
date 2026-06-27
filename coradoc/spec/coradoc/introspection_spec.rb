# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::Introspection do
  describe '.document_stats' do
    it 'counts children of a structural element' do
      doc = Coradoc::CoreModel::DocumentElement.new(
        title: 'My Doc',
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'one'),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'two')
        ]
      )
      stats = described_class.document_stats(doc)
      expect(stats[:title]).to eq('My Doc')
      expect(stats[:child_count]).to eq(2)
      expect(stats[:element_counts]).to be_a(Hash)
    end

    it 'returns title-only stats for non-structural models' do
      block = Coradoc::CoreModel::ParagraphBlock.new(content: 'para')
      stats = described_class.document_stats(block)
      expect(stats).to eq({})
    end
  end

  describe '.describe_element' do
    it 'renders type + title for elements with a title' do
      doc = Coradoc::CoreModel::DocumentElement.new(title: 'My Doc')
      expect(described_class.describe_element(doc)).to eq('DocumentElement: My Doc')
    end

    it 'renders type only for elements without title or content' do
      element = Coradoc::CoreModel::SectionElement.new
      expect(described_class.describe_element(element)).to eq('SectionElement')
    end

    it 'returns to_s for non-CoreModel inputs' do
      expect(described_class.describe_element(42)).to eq('42')
    end
  end

  describe Coradoc::Introspection::ElementCounter do
    it 'counts each visited node by its type key' do
      doc = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'one'),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'two')
        ]
      )
      counter = described_class.new
      counter.visit(doc)
      expect(counter.counts['paragraph']).to eq(2)
      expect(counter.counts['document']).to eq(1)
    end
  end
end
