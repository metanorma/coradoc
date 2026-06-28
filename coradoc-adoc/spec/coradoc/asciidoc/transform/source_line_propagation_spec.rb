# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

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
  def parse(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  def first_child(adoc)
    parse(adoc).children.first
  end

  describe 'paragraphs' do
    it 'records the line of the first paragraph' do
      doc = parse("Para 1\n\nPara 2\n")
      expect(doc.children[0].source_line).to eq(1)
    end

    it 'records the line of subsequent paragraphs' do
      doc = parse("Para 1\n\nPara 2\n")
      expect(doc.children[1].source_line).to eq(3)
    end

    it 'records correct lines when paragraphs are offset by a header' do
      doc = parse("= Title\n\nFirst body paragraph.\n\nSecond body paragraph.\n")
      paragraphs = doc.children.grep(Coradoc::CoreModel::ParagraphBlock)
      expect(paragraphs[0].source_line).to eq(3)
      expect(paragraphs[1].source_line).to eq(5)
    end
  end

  describe 'sections' do
    it 'records the line of the section heading' do
      adoc = <<~ADOC
        Preamble paragraph.

        == Section A

        Body under A.
      ADOC
      section = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(section.source_line).to eq(3)
    end

    it 'records nested section lines' do
      adoc = <<~ADOC
        == Parent

        Parent body.

        === Child
      ADOC
      parent = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      child = parent.children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(parent.source_line).to eq(1)
      expect(child.source_line).to eq(5)
    end
  end

  describe 'delimited blocks' do
    it 'records the line of a source block' do
      adoc = <<~ADOC
        Para.

        [source,ruby]
        ----
        puts 1
        ----
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of an example block' do
      adoc = <<~ADOC
        Para.

        ====
        Example body.
        ====
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::ExampleBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of a quote block' do
      adoc = <<~ADOC
        Para.

        ____
        Quote body.
        ____
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::QuoteBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of a sidebar block' do
      adoc = <<~ADOC
        Para.

        ****
        Sidebar body.
        ****
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::SidebarBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of a literal block' do
      adoc = <<~ADOC
        Para.

        ....
          Indented literal.
        ....
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::LiteralBlock) }
      expect(block.source_line).to eq(3)
    end
  end

  describe 'lists' do
    it 'records the line of a unordered list' do
      adoc = <<~ADOC
        Para.

        * one
        * two
      ADOC
      list = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(list.source_line).to eq(3)
    end

    it 'records source_line on individual list items' do
      adoc = <<~ADOC
        * one
        * two
        * three
      ADOC
      list = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(list.items[0].source_line).to eq(1)
      expect(list.items[1].source_line).to eq(2)
      expect(list.items[2].source_line).to eq(3)
    end

    it 'records the line of an ordered list' do
      adoc = <<~ADOC
        Para.

        . one
        . two
      ADOC
      list = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(list.source_line).to eq(3)
    end
  end

  describe 'tables' do
    it 'records the line of a table' do
      adoc = <<~ADOC
        Para.

        |===
        | A | B
        | 1 | 2
        |===
      ADOC
      table = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::Table) }
      expect(table.source_line).to eq(3)
    end
  end

  describe 'admonitions' do
    it 'records the line of a line-form admonition' do
      adoc = <<~ADOC
        Para.

        NOTE: This is a note.
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::AnnotationBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of a block-form admonition' do
      adoc = <<~ADOC
        Para.

        [NOTE]
        ====
        Block note body.
        ====
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::AnnotationBlock) }
      expect(block.source_line).to eq(3)
    end
  end

  describe 'block images' do
    it 'records the line of a block image' do
      adoc = <<~ADOC
        Para.

        image::diagram.png[]
      ADOC
      image = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::Image) }
      expect(image.source_line).to eq(3)
    end
  end

  describe 'typed cast blocks (abstract/partintro)' do
    it 'records the line of an abstract block' do
      adoc = <<~ADOC
        Para.

        [abstract]
        ====
        Abstract text.
        ====
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::AbstractBlock) }
      expect(block.source_line).to eq(3)
    end

    it 'records the line of a partintro block' do
      adoc = <<~ADOC
        = Book

        [partintro]
        --
        Introduction to the part.
        --
      ADOC
      block = parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::PartintroBlock) }
      expect(block.source_line).to eq(3)
    end
  end

  describe 'SourceLineExtractor' do
    let(:extractor) { Coradoc::AsciiDoc::Transformer::SourceLineExtractor }

    it 'returns nil for untracked values' do
      expect(extractor.extract(nil)).to be_nil
      expect(extractor.extract('string')).to be_nil
      expect(extractor.extract(123)).to be_nil
    end

    it 'returns source_line of a Model::Base' do
      model = Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 42)
      expect(extractor.extract(model)).to eq(42)
    end

    it 'walks a Hash to find the first source_line' do
      model_with_line = Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 7)
      hash = { a: nil, b: model_with_line }
      expect(extractor.extract(hash)).to eq(7)
    end

    it 'walks an Array to find the first source_line' do
      model_with_line = Coradoc::AsciiDoc::Model::TextElement.new(content: 'x', source_line: 11)
      expect(extractor.extract([nil, model_with_line])).to eq(11)
    end

    it 'extracts source_line from Parslet Slices produced by the parser' do
      parser = Coradoc::AsciiDoc::Parser::Base.new
      ast = parser.parse("line one\nline two\n")
      # Walk to a leaf Slice in the parsed tree.
      first_slice = find_first_slice(ast)
      expect(first_slice).to be_a(Parslet::Slice)
      line = extractor.extract(first_slice)
      expect(line).to eq(1)
    end

    def find_first_slice(node)
      return node if node.is_a?(Parslet::Slice)

      case node
      when Hash
        node.each_value do |v|
          s = find_first_slice(v)
          return s if s
        end
      when Array
        node.each do |v|
          s = find_first_slice(v)
          return s if s
        end
      end
      nil
    end
  end
end
