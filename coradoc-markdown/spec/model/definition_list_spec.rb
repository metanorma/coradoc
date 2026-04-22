# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Markdown::DefinitionList do
  describe '.new' do
    it 'creates a definition list with items' do
      term = Coradoc::Markdown::DefinitionTerm.new(
        text: 'kramdown',
        definitions: [
          Coradoc::Markdown::DefinitionItem.new(content: 'A Markdown parser')
        ]
      )
      list = described_class.new(items: [term])

      expect(list.items).to be_an(Array)
      expect(list.items.first).to be_a(Coradoc::Markdown::DefinitionTerm)
      expect(list.items.first.text).to eq('kramdown')
    end
  end

  describe '#to_md' do
    it 'serializes to Markdown format' do
      term = Coradoc::Markdown::DefinitionTerm.new(
        text: 'term',
        definitions: [
          Coradoc::Markdown::DefinitionItem.new(content: 'definition')
        ]
      )
      list = described_class.new(items: [term])

      expect(list.to_md).to eq("term\n: definition")
    end
  end
end

RSpec.describe Coradoc::Markdown::DefinitionTerm do
  describe '.new' do
    it 'creates a term with text' do
      term = described_class.new(text: 'API')

      expect(term.text).to eq('API')
      expect(term.definitions).to eq([])
    end

    it 'creates a term with definitions' do
      defn = Coradoc::Markdown::DefinitionItem.new(content: 'Application Programming Interface')
      term = described_class.new(text: 'API', definitions: [defn])

      expect(term.definitions).to be_an(Array)
      expect(term.definitions.first.content).to eq('Application Programming Interface')
    end
  end
end

RSpec.describe Coradoc::Markdown::DefinitionItem do
  describe '.new' do
    it 'creates a definition with content' do
      defn = described_class.new(content: 'A definition')

      expect(defn.content).to eq('A definition')
    end
  end
end

RSpec.describe 'Definition List Parsing' do
  let(:parser) { Coradoc::Markdown::Parser::BlockParser.new }

  describe 'simple definition list' do
    it 'parses a single term with definition' do
      result = parser.parse("kram\n: down\n")

      expect(result).to be_an(Array)
      expect(result.first).to have_key(:dl)
      dl = result.first[:dl]
      expect(dl).to be_an(Array)
      expect(dl.first).to have_key(:def_term)
      expect(dl[1]).to have_key(:def_content)
    end

    it 'parses multiple terms with definitions' do
      result = parser.parse("kram\n: down\n\nanother\n: definition\n")

      expect(result).to be_an(Array)
      expect(result.first).to have_key(:dl)
    end
  end

  describe 'definition list model transformation' do
    it 'transforms AST to DefinitionList model' do
      doc = Coradoc::Markdown.parse("kram\n: down\n")

      expect(doc.blocks.first).to be_a(Coradoc::Markdown::DefinitionList)
      list = doc.blocks.first
      expect(list.items).to be_an(Array)
      expect(list.items.first.text).to eq('kram')
      expect(list.items.first.definitions.first.content).to eq('down')
    end

    it 'handles multiple terms and definitions' do
      doc = Coradoc::Markdown.parse("term1\n: def1\n\nterm2\n: def2\n")

      expect(doc.blocks.first).to be_a(Coradoc::Markdown::DefinitionList)
      list = doc.blocks.first
      expect(list.items.length).to eq(2)
      expect(list.items[0].text).to eq('term1')
      expect(list.items[1].text).to eq('term2')
    end
  end
end
