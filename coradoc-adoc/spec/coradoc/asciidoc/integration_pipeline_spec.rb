# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration pipeline fixes' do
  def parse_to_core(adoc)
    ast = Coradoc::AsciiDoc::Parser::Base.parse(adoc)
    model = Coradoc::AsciiDoc::Transformer.transform(ast)
    Coradoc::AsciiDoc::Transform::ToCoreModel.transform(model)
  end

  def parse_to_ast(adoc)
    Coradoc::AsciiDoc::Parser::Base.parse(adoc)
  end

  describe 'Fix 01: Page break parsing' do
    it 'parses <<< as page_break at document level' do
      ast = parse_to_ast("= Title\n\n<<<\n")
      doc_nodes = ast[:document]
      page_breaks = doc_nodes.select { |n| n.is_a?(Hash) && n.key?(:page_break) }
      expect(page_breaks.length).to eq(1)
    end

    it 'parses <<< as page_break inside sections' do
      ast = parse_to_ast("== Section\n\n<<<\n\nSome text\n")
      doc_nodes = ast[:document]
      section = doc_nodes.find { |n| n.is_a?(Hash) && n.key?(:section) }
      contents = section[:section][:contents]
      page_breaks = contents.select { |n| n.is_a?(Hash) && n.key?(:page_break) }
      expect(page_breaks.length).to eq(1)
    end

    it 'does not capture <<< as paragraph text' do
      ast = parse_to_ast("= Title\n\n<<<\n")
      doc_nodes = ast[:document]
      paragraphs = doc_nodes.select { |n| n.is_a?(Hash) && n.key?(:paragraph) }
      paragraph_texts = paragraphs.map { |p| p[:paragraph][:lines].map { |l| l[:text].to_s }.join }
      expect(paragraph_texts).not_to include('<<<')
    end

    it 'transforms page_break through to CoreModel as nil (filtered out)' do
      core = parse_to_core("= Title\n\nHello\n\n<<<\n\n== Section\n")
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
      expect(core.children.length).to eq(2) # paragraph + section, no page break
    end
  end

  describe 'Fix 02+03: Table row grouping and header detection' do
    it 'groups cells into rows by column count' do
      adoc = <<~ADOC
        = Doc

        [cols="2"]
        |===
        | A | B
        | C | D
        | E | F
        |===
      ADOC

      core = parse_to_core(adoc)
      table = find_first_table(core)
      expect(table).not_to be_nil
      expect(table.rows.length).to eq(3)
      table.rows.each do |row|
        expect(row.cells.length).to eq(2)
      end
    end

    it 'marks the first row as header' do
      adoc = <<~ADOC
        = Doc

        [cols="2"]
        |===
        | Header A | Header B
        | Data 1 | Data 2
        |===
      ADOC

      core = parse_to_core(adoc)
      table = find_first_table(core)
      expect(table.rows.first.header).to be true
      expect(table.rows.last.header).to be false
    end

    it 'handles 3-column tables' do
      adoc = <<~ADOC
        = Doc

        [cols="3"]
        |===
        | A | B | C
        | D | E | F
        |===
      ADOC

      core = parse_to_core(adoc)
      table = find_first_table(core)
      expect(table.rows.length).to eq(2)
      table.rows.each { |row| expect(row.cells.length).to eq(3) }
    end
  end

  describe 'Fix 04: LineBreak leak' do
    it 'does not leak LineBreak elements into CoreModel children' do
      adoc = <<~ADOC
        = Title

        First paragraph.

        Second paragraph.
      ADOC

      core = parse_to_core(adoc)
      core.children.each do |child|
        next if child.is_a?(String) && child.strip.empty?

        expect(child).not_to be_a(Coradoc::AsciiDoc::Model::LineBreak)
      end
    end

    it 'does not leak PageBreak elements into CoreModel children' do
      core = parse_to_core("= Title\n\n<<<\n\n== Section\n")
      core.children.each do |child|
        expect(child).not_to be_a(Coradoc::AsciiDoc::Model::Break::PageBreak)
      end
    end
  end

  describe 'Fix 05: Document attributes' do
    it 'preserves document attributes in CoreModel' do
      skip 'Parser does not yet propagate document attributes to CoreModel'
      adoc = <<~ADOC
        = My Document
        :author: John
        :revdate: 2024-01-01

        Content here.
      ADOC

      core = parse_to_core(adoc)
      expect(core.attributes).to include('author' => 'John', 'revdate' => '2024-01-01')
    end

    it 'handles multiple attributes' do
      skip 'Parser does not yet propagate document attributes to CoreModel'
      adoc = <<~ADOC
        = Doc
        :docnumber: 1
        :edition: 2
        :language: zh-Hant

        Text.
      ADOC

      core = parse_to_core(adoc)
      expect(core.attributes).to include(
        'docnumber' => '1',
        'edition' => '2',
        'language' => 'zh-Hant'
      )
    end
  end

  describe 'Fix 07: Cross-references' do
    it 'parses simple cross-reference <<id>>' do
      skip 'Cross-reference parsing not yet implemented'
      adoc = <<~ADOC
        = Doc

        See <<introduction>> for details.
      ADOC

      core = parse_to_core(adoc)
      xrefs = find_all_xrefs(core)
      expect(xrefs.length).to be >= 1
      expect(xrefs.first.target).to eq('introduction')
    end

    it 'parses cross-reference with text <<id,text>>' do
      skip 'Cross-reference parsing not yet implemented'
      adoc = <<~ADOC
        = Doc

        See <<introduction,Introduction>> for details.
      ADOC

      core = parse_to_core(adoc)
      xrefs = find_all_xrefs(core)
      expect(xrefs.length).to be >= 1
      expect(xrefs.first.target).to eq('introduction')
      expect(xrefs.first.content).to eq('Introduction')
    end

    it 'parses multiple cross-references' do
      skip 'Cross-reference parsing not yet implemented'
      adoc = <<~ADOC
        = Doc

        See <<section-a>> and <<section-b,Section B>>.
      ADOC

      core = parse_to_core(adoc)
      xrefs = find_all_xrefs(core)
      expect(xrefs.length).to be >= 2
      targets = xrefs.map(&:target)
      expect(targets).to include('section-a', 'section-b')
    end
  end

  describe 'Fix 06: Section hierarchy — bold in list items' do
    it 'parses ordered list items starting with bold formatting' do
      ast = parse_to_ast(". *First* text\n")
      doc_nodes = ast[:document]
      lists = doc_nodes.select { |n| n.is_a?(Hash) && n.key?(:list) }
      expect(lists.length).to eq(1)
    end

    it 'parses ordered list items starting with bold inside a section' do
      adoc = <<~ADOC
        == Section

        . *Bold item* — description
        . Normal item
      ADOC

      ast = parse_to_ast(adoc)
      section = ast[:document].find { |n| n.is_a?(Hash) && n.key?(:section) }
      contents = section[:section][:contents]
      lists = contents.select { |n| n.is_a?(Hash) && n.key?(:list) }
      expect(lists.length).to eq(1)
    end

    it 'parses source blocks with YAML delimiters inside' do
      adoc = <<~ADOC
        = Doc

        [source]
        ----
        ---
        frontmatter
        ---
        ----
      ADOC

      core = parse_to_core(adoc)
      expect(core).to be_a(Coradoc::CoreModel::StructuralElement)
    end

    it 'does not let highlight unconstrained match across lines' do
      ast = parse_to_ast("## heading\nSome text\n")
      doc_nodes = ast[:document]
      paragraphs = doc_nodes.select { |n| n.is_a?(Hash) && n.key?(:paragraph) }
      highlight_nodes = paragraphs.select do |p|
        text = p[:paragraph]
        text.to_s.include?('highlight')
      end
      expect(highlight_nodes).to be_empty
    end
  end

  describe 'Fix 08: List marker_type' do
    it 'sets marker_type to unordered for bullet lists' do
      adoc = <<~ADOC
        = Doc

        * Item one
        * Item two
        * Item three
      ADOC

      core = parse_to_core(adoc)
      lists = find_all_lists(core)
      expect(lists).not_to be_empty
      expect(lists.first.marker_type).to eq('unordered')
    end

    it 'sets marker_type to ordered for numbered lists' do
      adoc = <<~ADOC
        = Doc

        . First item
        . Second item
        . Third item
      ADOC

      core = parse_to_core(adoc)
      lists = find_all_lists(core)
      expect(lists).not_to be_empty
      expect(lists.first.marker_type).to eq('ordered')
    end
  end

  private

  def find_first_table(el)
    return el if el.is_a?(Coradoc::CoreModel::Table)
    return nil unless el.is_a?(Coradoc::CoreModel::Base)

    if el.class.attributes.key?(:children) && el.children
      el.children.each do |child|
        result = find_first_table(child)
        return result if result
      end
    end

    nil
  end

  def find_all_xrefs(el)
    xrefs = []
    return xrefs unless el

    xrefs << el if el.is_a?(Coradoc::CoreModel::InlineElement) && el.format_type == 'xref'

    children = if el.respond_to?(:children) && el.children
                 el.children
               elsif el.is_a?(Coradoc::CoreModel::Base) && el.class.attributes.key?(:children)
                 el.children
               end

    if children
      children.each { |c| xrefs.concat(find_all_xrefs(c)) }
    end

    xrefs
  end

  def find_all_lists(el)
    lists = []
    return lists unless el

    lists << el if el.is_a?(Coradoc::CoreModel::ListBlock)

    if el.is_a?(Coradoc::CoreModel::ListBlock) && el.items
      el.items.each { |c| lists.concat(find_all_lists(c)) }
    elsif el.is_a?(Coradoc::CoreModel::Base) && el.class.attributes.key?(:children) && el.children
      el.children.each { |c| lists.concat(find_all_lists(c)) }
    end

    lists
  end
end
