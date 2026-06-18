# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc definition list parsing' do
  let(:parser) { Coradoc::AsciiDoc::Parser::Base.new }
  let(:transformer) { Coradoc::AsciiDoc::Transformer.new }

  def parse_to_core(input)
    Coradoc.parse(input, format: :asciidoc)
  end

  describe 'flat definition list (::)' do
    it 'parses a simple definition list' do
      core = parse_to_core("term1:: def1\nterm2:: def2\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl).not_to be_nil
      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('term1')
      expect(dl.items[0].definitions).to eq(['def1'])
      expect(dl.items[1].term).to eq('term2')
    end
  end

  describe 'terms containing colons' do
    it 'parses terms with inline colons (e.g. `:doctype:`)' do
      core = parse_to_core("`:doctype:`:: Has values\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl).not_to be_nil
      expect(dl.items.first.term).to eq(':doctype:')
      expect(dl.items.first.definitions).to eq(['Has values'])
    end
  end

  describe 'nested definition lists (:::)' do
    it 'nests ::: items under preceding :: item' do
      core = parse_to_core(<<~ADOC)
        parent:: parent def
        child1::: child def1
        child2::: child def2
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      parent = dl.items.first
      expect(parent.term).to eq('parent')
      expect(parent.nested).to be_a(Coradoc::CoreModel::DefinitionList)
      expect(parent.nested.items.length).to eq(2)
      expect(parent.nested.items[0].term).to eq('child1')
      expect(parent.nested.items[1].term).to eq('child2')
    end

    it 'returns to parent level after nested items' do
      core = parse_to_core(<<~ADOC)
        a:: def a
        nested::: nested def
        b:: def b
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('a')
      expect(dl.items[0].nested.items.length).to eq(1)
      expect(dl.items[1].term).to eq('b')
      expect(dl.items[1].nested).to be_nil
    end
  end

  describe 'deep nesting (3+ levels)' do
    it 'nests ::, :::, :::: correctly' do
      core = parse_to_core(<<~ADOC)
        l1:: def1
        l2::: def2
        l3:::: def3
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      l1 = dl.items.first
      expect(l1.term).to eq('l1')
      expect(l1.nested.items.length).to eq(1)
      l2 = l1.nested.items.first
      expect(l2.term).to eq('l2')
      expect(l2.nested.items.length).to eq(1)
      l3 = l2.nested.items.first
      expect(l3.term).to eq('l3')
    end
  end

  describe 'standalone ::: list' do
    it 'parses ::: items without a :: parent as a flat list' do
      core = parse_to_core(<<~ADOC)
        item1::: def1
        item2::: def2
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl).not_to be_nil
      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('item1')
      expect(dl.items[1].term).to eq('item2')
    end
  end

  describe 'metanorma.org proposal example' do
    it 'parses the exact example from the proposal' do
      core = parse_to_core(<<~ADOC)
        `:doctype:`:: Has its possible values defined by ...

        `international-standard`::: International Standard (IS)
        `technical-specification`::: Technical Specification (TS)
        `technical-report`::: Technical Report (TR)
        `guide`::: Guide (Guide)
      ADOC

      dlists = core.children.select { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dlists.length).to eq(1)

      dl = dlists.first
      expect(dl.items.length).to eq(1)
      parent = dl.items.first
      expect(parent.term).to eq(':doctype:')
      expect(parent.definitions).to eq(['Has its possible values defined by ...'])
      expect(parent.nested.items.length).to eq(4)
      expect(parent.nested.items.map(&:term)).to eq(
        %w[international-standard technical-specification technical-report guide]
      )
    end
  end

  describe 'attribute list on definition list' do
    def find_adoc_dlist(node)
      return node if node.is_a?(Coradoc::AsciiDoc::Model::List::Definition)

      children = node.respond_to?(:sections) ? node.sections : Array(node.blocks)
      children.flat_map { |c| [find_adoc_dlist(c)].compact }.first
    end

    it 'parses [%hardbreaks] prefix without raising (regression)' do
      expect { parse_to_core("[%hardbreaks]\nterm:: def\n") }.not_to raise_error
    end

    it 'parses [%metadata] and preserves the attribute on the AsciiDoc model' do
      doc = Coradoc::AsciiDoc.parse("[%metadata]\nidentifier:: abc\n")
      dlist = find_adoc_dlist(doc)

      expect(dlist).to be_a(Coradoc::AsciiDoc::Model::List::Definition)
    end

    it 'preserves [%metadata] attribute value through attrs.to_adoc' do
      doc = Coradoc::AsciiDoc.parse("[%metadata]\nidentifier:: abc\n")
      dlist = find_adoc_dlist(doc)

      expect(dlist.attrs.to_adoc(show_empty: false)).to eq('[%metadata]')
    end

    it 'parses [.glossary] and preserves it on the AsciiDoc model' do
      doc = Coradoc::AsciiDoc.parse("[.glossary]\nterm:: def\n")
      dlist = find_adoc_dlist(doc)

      expect(dlist.attrs.to_adoc(show_empty: false)).to eq('[.glossary]')
    end

    it 'serializes the attribute list back before the items' do
      original = "[%metadata]\nidentifier:: abc\nsubject:: s\n"
      serialized = Coradoc::AsciiDoc.serialize(Coradoc::AsciiDoc.parse(original))

      expect(serialized).to include("[%metadata]\nidentifier:: abc")
    end

    it 'round-trips the attribute list through serialize/parse' do
      original = "[%metadata]\nidentifier:: abc\nsubject:: s\n"
      serialized = Coradoc::AsciiDoc.serialize(Coradoc::AsciiDoc.parse(original))
      reparsed = find_adoc_dlist(Coradoc::AsciiDoc.parse(serialized))

      expect(reparsed.attrs.to_adoc(show_empty: false)).to eq('[%metadata]')
    end
  end
end
