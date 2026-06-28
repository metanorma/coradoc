# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Walks a parsed Parslet AST tree (Hash/Array/Slice) and returns the
# first +Parslet::Slice+ encountered. Used by the SourceLineExtractor
# spec to exercise the real Slice code path without hand-constructing
# a Parslet::Slice (which requires a line_cache).
class SliceFinder
  class << self
    def first(node)
      return node if node.is_a?(Parslet::Slice)

      walk(node)
    end

    private

    def walk(node)
      return nil unless node.is_a?(Enumerable)
      return walk_pairs(node) if node.is_a?(Hash)

      walk_array(node)
    end

    def walk_pairs(hash)
      hash.each_value do |v|
        s = first(v)
        return s if s
      end
      nil
    end

    def walk_array(array)
      array.each do |v|
        s = first(v)
        return s if s
      end
      nil
    end
  end
end

# Source-line propagation (Issue 1, STATUS-2026-06-28).
#
# Every CoreModel block must carry a 1-indexed +source_line+ so consumers
# (linters, formatters, editor integrations) can map AST nodes back to the
# source text. Parslet tracks byte offsets on every +Parslet::Slice+; the
# AsciiDoc transformer funnels those positions through
# +Transformer::SourceLineExtractor+ into +Model::Base#source_line+, and
# the ToCoreModel transformers propagate the line onto the corresponding
# CoreModel types.
RSpec.describe 'Source-line propagation', :asciidoc do
  let(:extractor) { Coradoc::AsciiDoc::Transformer::SourceLineExtractor }
  let(:two_paras) { parse("Para 1\n\nPara 2\n") }

  def parse(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  def find_child(parsed, type)
    parsed.children.find { |c| c.is_a?(type) }
  end

  def block_at_line(adoc, type)
    find_child(parse(adoc), type).source_line
  end

  def child_source_lines(parsed, type)
    find_child(parsed, type).children.map(&:source_line)
  end

  it 'records the line of the first paragraph' do
    expect(two_paras.children[0].source_line).to eq(1)
  end

  it 'records the line of subsequent paragraphs' do
    expect(two_paras.children[1].source_line).to eq(3)
  end

  it 'records correct lines when paragraphs are offset by a header' do
    doc = parse("= Title\n\nFirst body paragraph.\n\nSecond body paragraph.\n")
    paragraphs = doc.children.grep(Coradoc::CoreModel::ParagraphBlock)
    expect(paragraphs.map(&:source_line)).to eq([3, 5])
  end

  it 'records the line of the section heading' do
    adoc = "Preamble paragraph.\n\n== Section A\n\nBody under A.\n"
    expect(find_child(parse(adoc), Coradoc::CoreModel::SectionElement).source_line).to eq(3)
  end

  it 'records nested section lines' do
    adoc = "== Parent\n\nParent body.\n\n=== Child\n"
    parent = find_child(parse(adoc), Coradoc::CoreModel::SectionElement)
    child = find_child(parent, Coradoc::CoreModel::SectionElement)
    expect([parent.source_line, child.source_line]).to eq([1, 5])
  end

  it 'records the line of a source block' do
    adoc = "Para.\n\n[source,ruby]\n----\nputs 1\n----\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::SourceBlock)).to eq(3)
  end

  it 'records the line of an example block' do
    adoc = "Para.\n\n====\nExample body.\n====\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::ExampleBlock)).to eq(3)
  end

  it 'records the line of a quote block' do
    adoc = "Para.\n\n____\nQuote body.\n____\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::QuoteBlock)).to eq(3)
  end

  it 'records the line of a sidebar block' do
    adoc = "Para.\n\n****\nSidebar body.\n****\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::SidebarBlock)).to eq(3)
  end

  it 'records the line of a literal block' do
    adoc = "Para.\n\n....\n  Indented literal.\n....\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::LiteralBlock)).to eq(3)
  end

  it 'records the line of an unordered list' do
    adoc = "Para.\n\n* one\n* two\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::ListBlock)).to eq(3)
  end

  it 'records source_line on individual list items' do
    list = find_child(parse("* one\n* two\n* three\n"), Coradoc::CoreModel::ListBlock)
    expect(list.items.map(&:source_line)).to eq([1, 2, 3])
  end

  it 'records the line of an ordered list' do
    adoc = "Para.\n\n. one\n. two\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::ListBlock)).to eq(3)
  end

  it 'records the line of a table' do
    adoc = "Para.\n\n|===\n| A | B\n| 1 | 2\n|===\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::Table)).to eq(3)
  end

  it 'records the line of a line-form admonition' do
    adoc = "Para.\n\nNOTE: This is a note.\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::AnnotationBlock)).to eq(3)
  end

  it 'records the line of a block-form admonition' do
    adoc = "Para.\n\n[NOTE]\n====\nBlock note body.\n====\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::AnnotationBlock)).to eq(3)
  end

  it 'records the line of a block image' do
    adoc = "Para.\n\nimage::diagram.png[]\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::Image)).to eq(3)
  end

  it 'records the line of an abstract block' do
    adoc = "Para.\n\n[abstract]\n====\nAbstract text.\n====\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::AbstractBlock)).to eq(3)
  end

  it 'records the line of a partintro block' do
    adoc = "= Book\n\n[partintro]\n--\nIntroduction to the part.\n--\n"
    expect(block_at_line(adoc, Coradoc::CoreModel::PartintroBlock)).to eq(3)
  end

  describe Coradoc::AsciiDoc::Transformer::SourceLineExtractor do
    subject(:line) { described_class.extract(node) }

    context 'with nil' do
      let(:node) { nil }

      it { is_expected.to be_nil }
    end

    context 'with a String' do
      let(:node) { 'string' }

      it { is_expected.to be_nil }
    end

    context 'with a Numeric' do
      let(:node) { 123 }

      it { is_expected.to be_nil }
    end

    context 'with a Model::Base carrying source_line' do
      let(:node) do
        Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 42)
      end

      it { is_expected.to eq(42) }
    end

    context 'with a Hash containing a Model::Base' do
      let(:node) do
        { a: nil,
          b: Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 7) }
      end

      it { is_expected.to eq(7) }
    end

    context 'with an Array containing a Model::Base' do
      let(:node) do
        [nil, Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 11)]
      end

      it { is_expected.to eq(11) }
    end

    context 'with a real Parslet::Slice from the parser' do
      let(:node) do
        ast = Coradoc::AsciiDoc::Parser::Base.new.parse("line one\nline two\n")
        SliceFinder.first(ast)
      end

      it 'returns the 1-indexed source line' do
        expect(line).to eq(1)
      end

      it 'is a Parslet::Slice' do
        expect(node).to be_a(Parslet::Slice)
      end
    end
  end
end
