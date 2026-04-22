# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/core_model'

RSpec.describe Coradoc::CoreModel::Footnote do
  describe '.new' do
    it 'creates a footnote with id and content' do
      fn = described_class.new(id: '1', content: 'This is a footnote')

      expect(fn.id).to eq('1')
      expect(fn.content).to eq('This is a footnote')
      expect(fn.backlink).to be true
    end

    it 'creates a footnote with backlink disabled' do
      fn = described_class.new(id: 'fn1', content: 'No backlink', backlink: false)

      expect(fn.id).to eq('fn1')
      expect(fn.backlink).to be false
    end

    it 'creates a footnote with inline content' do
      fn = described_class.new(
        id: '2',
        content: 'Main content',
        inline_content: %w[First Second]
      )

      expect(fn.inline_content).to eq(%w[First Second])
    end
  end

  describe '#==' do
    it 'compares footnotes by id and content' do
      fn1 = described_class.new(id: '1', content: 'Same')
      fn2 = described_class.new(id: '1', content: 'Same')

      expect(fn1).to eq(fn2)
    end

    it 'differentiates footnotes with different ids' do
      fn1 = described_class.new(id: '1', content: 'Same')
      fn2 = described_class.new(id: '2', content: 'Same')

      expect(fn1).not_to eq(fn2)
    end
  end
end

RSpec.describe Coradoc::CoreModel::FootnoteReference do
  describe '.new' do
    it 'creates a footnote reference with id' do
      ref = described_class.new(id: 'fn1')

      expect(ref.id).to eq('fn1')
    end
  end
end

RSpec.describe Coradoc::CoreModel::Abbreviation do
  describe '.new' do
    it 'creates an abbreviation with term and definition' do
      abbr = described_class.new(term: 'API', definition: 'Application Programming Interface')

      expect(abbr.term).to eq('API')
      expect(abbr.definition).to eq('Application Programming Interface')
    end
  end

  describe '#==' do
    it 'compares abbreviations by term and definition' do
      abbr1 = described_class.new(term: 'API', definition: 'Application Programming Interface')
      abbr2 = described_class.new(term: 'API', definition: 'Application Programming Interface')

      expect(abbr1).to eq(abbr2)
    end
  end
end

RSpec.describe Coradoc::CoreModel::DefinitionItem do
  describe '.new' do
    it 'creates a definition item with term and definitions' do
      item = described_class.new(
        term: 'API',
        definitions: ['Application Programming Interface', 'A set of protocols']
      )

      expect(item.term).to eq('API')
      expect(item.definitions).to eq(['Application Programming Interface', 'A set of protocols'])
    end

    it 'creates a definition item with empty definitions' do
      item = described_class.new(term: 'Term', definitions: [])

      expect(item.term).to eq('Term')
      expect(item.definitions).to eq([])
    end
  end
end

RSpec.describe Coradoc::CoreModel::DefinitionList do
  describe '.new' do
    it 'creates a definition list with items' do
      item1 = Coradoc::CoreModel::DefinitionItem.new(term: 'API', definitions: ['Application Programming Interface'])
      item2 = Coradoc::CoreModel::DefinitionItem.new(term: 'REST', definitions: ['Representational State Transfer'])

      list = described_class.new(items: [item1, item2])

      expect(list.items.length).to eq(2)
      expect(list.items.first.term).to eq('API')
      expect(list.items.last.term).to eq('REST')
    end

    it 'creates an empty definition list' do
      list = described_class.new(items: [])

      expect(list.items).to eq([])
    end
  end
end
