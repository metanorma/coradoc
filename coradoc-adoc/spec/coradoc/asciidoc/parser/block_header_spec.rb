# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc/parser/base'
require 'coradoc/asciidoc/transformer'

# Captures stderr/stdout "Duplicate subtrees while merging result" warnings
# from Parslet so each example can assert they no longer fire.
def capturing_parslet_warnings
  captured = []
  allow(Kernel).to receive(:warn) { |msg| captured << msg }
  yield
  captured
end

RSpec.describe Coradoc::AsciiDoc::Parser::BlockHeader do
  let(:parser) { Coradoc::AsciiDoc::Parser::Base.new }
  let(:transformer) { Coradoc::AsciiDoc::Transformer.new }

  def parse_to_core(input)
    tree = parser.parse(input)
    transformer.apply(tree)
  end

  # All header-bearing elements below should produce zero warnings on parse.
  # The regression motivating this spec was Parslet's "Duplicate subtrees
  # while merging result" warning, which silently discarded all but the
  # last `[...]` block when multiple were stacked before a delimiter.
  shared_examples 'no duplicate-subtree warning' do
    it 'does not emit a Duplicate subtrees warning' do
      warnings = capturing_parslet_warnings { parse_to_core(input) }
      expect(warnings.grep(/Duplicate subtrees/)).to be_empty
    end
  end

  describe 'on a source block' do
    describe 'with no header' do
      let(:input) { "----\nplain code\n----\n" }
      include_examples 'no duplicate-subtree warning'

      it 'builds a SourceCode with nil attributes' do
        block = parse_to_core(input).sections.first
        expect(block).to be_a(Coradoc::AsciiDoc::Model::Block::SourceCode)
        expect(block.attributes).to be_nil
      end
    end

    describe 'with a single attribute list' do
      let(:input) { "[source,ruby]\n----\nputs 'hi'\n----\n" }
      include_examples 'no duplicate-subtree warning'

      it 'captures every positional value' do
        block = parse_to_core(input).sections.first
        expect(block.attributes).to be_a(Coradoc::AsciiDoc::Model::AttributeList)
        expect(block.attributes.positional.map(&:value)).to eq(%w[source ruby])
      end
    end

    describe 'with multiple stacked attribute lists' do
      let(:input) { "[role=quote]\n[source,ruby]\n----\nputs 'hi'\n----\n" }
      include_examples 'no duplicate-subtree warning'

      it 'merges positional and named values across both lists' do
        block = parse_to_core(input).sections.first
        expect(block.attributes).to be_a(Coradoc::AsciiDoc::Model::AttributeList)
        expect(block.attributes.positional.map(&:value)).to eq(%w[source ruby])
        named = block.attributes.named.map { |n| [n.name, n.value] }
        expect(named).to include(['role', ['quote']])
      end
    end

    describe 'with title, id, and a single attribute list' do
      let(:input) { ".My Title\n[#demo]\n[source,ruby]\n----\ncode\n----\n" }
      include_examples 'no duplicate-subtree warning'

      it 'captures title, id, and attributes' do
        block = parse_to_core(input).sections.first
        expect(block.title.to_s).to eq('My Title')
        expect(block.id.to_s).to eq('demo')
        expect(block.attributes.positional.map(&:value)).to eq(%w[source ruby])
      end
    end
  end

  describe 'on a table' do
    let(:input) do
      <<~ADOC
        [cols="2"]
        [%header]
        |===
        | A | B
        | 1 | 2
        |===
      ADOC
    end
    include_examples 'no duplicate-subtree warning'

    it 'merges both attribute lists into one AttributeList on the Table' do
      table = parse_to_core(input).sections.first
      expect(table).to be_a(Coradoc::AsciiDoc::Model::Table)
      expect(table.attrs).to be_a(Coradoc::AsciiDoc::Model::AttributeList)
      positional = table.attrs.positional.map(&:value)
      named = table.attrs.named.map { |n| [n.name, n.value] }
      expect(positional).to include('%header')
      expect(named).to include(['cols', ['"2"']])
    end
  end

  describe 'on a block image' do
    let(:input) { "[#img1]\nimage::diagram.png[Diagram]\n" }
    include_examples 'no duplicate-subtree warning'

    it 'captures id and attributes' do
      result = parse_to_core(input)
      image = result.sections.first
      expect(image).to be_a(Coradoc::AsciiDoc::Model::Image::BlockImage)
      expect(image.id.to_s).to eq('img1')
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Transformer::AttributeListNormalizer do
  let(:list_klass) { Coradoc::AsciiDoc::Model::AttributeList }
  let(:normalizer) { described_class }

  def build_list(positional: [], named: [])
    list = list_klass.new
    positional.each { |v| list.add_positional(v) }
    named.each { |k, v| list.add_named(k, v) }
    list
  end

  it 'returns nil for nil' do
    expect(normalizer.coerce(nil)).to be_nil
  end

  it 'returns the same object for a single AttributeList' do
    list = build_list(positional: %w[source])
    expect(normalizer.coerce(list)).to equal(list)
  end

  it 'returns the single AttributeList from a one-element Array' do
    list = build_list(positional: %w[source])
    expect(normalizer.coerce([list])).to equal(list)
  end

  it 'flattens an Array<{ attribute_list: <AttributeList> }>' do
    inner = build_list(positional: %w[source])
    wrapped = { attribute_list: inner }
    expect(normalizer.coerce([wrapped])).to equal(inner)
  end

  it 'merges multiple AttributeLists into a single one' do
    first = build_list(positional: %w[source], named: [['role', 'quote']])
    second = build_list(positional: %w[ruby])

    merged = normalizer.coerce([first, second])
    expect(merged).to be_a(list_klass)
    expect(merged.positional.map(&:value)).to eq(%w[source ruby])
    expect(merged.named.map { |n| [n.name, n.value] })
      .to include(['role', ['quote']])
  end

  it 'returns nil for an empty Array' do
    expect(normalizer.coerce([])).to be_nil
  end
end
