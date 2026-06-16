# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::DefinitionItem do
  describe '.new' do
    it 'creates a definition item with term and definitions' do
      item = described_class.new(
        term: 'API',
        definitions: ['Application Programming Interface']
      )

      expect(item.term).to eq('API')
      expect(item.definitions).to eq(['Application Programming Interface'])
    end

    it 'creates a definition item with structured term children' do
      bold = Coradoc::CoreModel::BoldElement.new(content: 'HTML')
      item = described_class.new(
        term: 'HTML',
        definitions: ['HyperText Markup Language'],
        term_children: [bold],
        definition_children: ['HyperText Markup Language']
      )

      expect(item.term_children).to eq([bold])
      expect(item.definition_children).to eq(['HyperText Markup Language'])
    end

    it 'defaults term_children and definition_children to empty arrays' do
      item = described_class.new(term: 'test')

      expect(item.term_children).to eq([])
      expect(item.definition_children).to eq([])
    end

    it 'coerces nil children to empty arrays on setter' do
      item = described_class.new(term: 'test')
      item.term_children = nil
      item.definition_children = nil

      expect(item.term_children).to eq([])
      expect(item.definition_children).to eq([])
    end
  end

  describe '#term_renderable' do
    it 'returns term string when term_children is empty' do
      item = described_class.new(term: 'API', definitions: ['def'])

      expect(item.term_renderable).to eq('API')
    end

    it 'returns term string when term_children are all strings' do
      item = described_class.new(
        term: 'HTML',
        definitions: ['def'],
        term_children: ['HyperText', ' ', 'Markup Language']
      )

      expect(item.term_renderable).to eq('HTML')
    end

    it 'returns term_children when they contain InlineElements' do
      bold = Coradoc::CoreModel::BoldElement.new(content: 'important')
      item = described_class.new(
        term: 'important',
        definitions: ['def'],
        term_children: [bold]
      )

      expect(item.term_renderable).to eq([bold])
    end
  end

  describe '#definition_renderable' do
    it 'returns definitions when definition_children is empty' do
      item = described_class.new(term: 'API', definitions: ['def'])

      expect(item.definition_renderable).to eq(['def'])
    end

    it 'returns definition_children when they contain InlineElements' do
      link = Coradoc::CoreModel::LinkElement.new(content: 'click', target: 'https://example.com')
      item = described_class.new(
        term: 'link',
        definitions: ['click here'],
        definition_children: [link]
      )

      expect(item.definition_renderable).to eq([link])
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end

  describe 'nested definition lists' do
    it 'accepts a nested DefinitionList' do
      nested_list = Coradoc::CoreModel::DefinitionList.new(
        items: [described_class.new(term: 'child', definitions: ['nested def'])]
      )
      parent = described_class.new(
        term: 'parent',
        definitions: ['parent def'],
        nested: nested_list
      )

      expect(parent.nested).to be_a(Coradoc::CoreModel::DefinitionList)
      expect(parent.nested.items.first.term).to eq('child')
    end

    it 'defaults nested to nil' do
      item = described_class.new(term: 'leaf')

      expect(item.nested).to be_nil
    end
  end

  describe '#semantically_equivalent?' do
    it 'returns true for identical definition items' do
      item1 = described_class.new(term: 'API', definitions: ['def1'])
      item2 = described_class.new(term: 'API', definitions: ['def1'])

      expect(item1.semantically_equivalent?(item2)).to be true
    end

    it 'returns false for different terms' do
      item1 = described_class.new(term: 'API', definitions: ['def1'])
      item2 = described_class.new(term: 'REST', definitions: ['def1'])

      expect(item1.semantically_equivalent?(item2)).to be false
    end

    it 'compares term_children and definition_children' do
      bold = Coradoc::CoreModel::BoldElement.new(content: 'API')
      item1 = described_class.new(term: 'API', definitions: ['def'], term_children: [bold])
      item2 = described_class.new(term: 'API', definitions: ['def'])

      expect(item1.semantically_equivalent?(item2)).to be false
    end
  end
end
