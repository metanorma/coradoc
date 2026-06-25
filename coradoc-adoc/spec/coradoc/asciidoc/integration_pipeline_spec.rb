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

  describe 'Fix 09: Nested source block inside example block' do
    it 'parses [source] inside [example] as nested blocks' do
      adoc = <<~ADOC
        = Doc

        [example]
        ====
        Some text.

        [source]
        ----
        code here
        ----
        ====
      ADOC

      core = parse_to_core(adoc)
      example = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ExampleBlock) }
      expect(example).not_to be_nil
      expect(example.children).not_to be_empty

      source = example.children.find { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(source).not_to be_nil
    end
  end

  describe 'Fix 10: Table escaped delimiters' do
    it 'handles \\| in table cell content' do
      adoc = <<~ADOC
        = Doc

        |===
        | A \\| B | C
        |===
      ADOC

      core = parse_to_core(adoc)
      table = find_first_table(core)
      expect(table).not_to be_nil
      first_cell = table.rows.first.cells.first
      expect(first_cell.content.strip).to eq('A | B')
    end
  end

  describe 'Fix 11: Nested list parsing' do
    it 'parses ** as nested unordered list items' do
      adoc = <<~ADOC
        = Doc

        * First item
        ** Nested item
        * Second item
      ADOC

      core = parse_to_core(adoc)
      lists = find_all_lists(core)
      expect(lists).not_to be_empty
      top_list = lists.first
      expect(top_list.marker_type).to eq('unordered')

      first_item = top_list.items.first
      nested = first_item.children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(nested).not_to be_nil
      expect(nested.marker_type).to eq('unordered')
    end

    it 'parses .. as nested ordered list items' do
      adoc = <<~ADOC
        = Doc

        . First item
        .. Nested item
        . Second item
      ADOC

      core = parse_to_core(adoc)
      lists = find_all_lists(core)
      expect(lists).not_to be_empty
      top_list = lists.first
      expect(top_list.marker_type).to eq('ordered')

      first_item = top_list.items.first
      nested = first_item.children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(nested).not_to be_nil
      expect(nested.marker_type).to eq('ordered')
    end
  end

  describe 'Fix 12: Hierarchical section IDs' do
    it 'generates unique IDs for same-titled sections under different parents' do
      adoc = <<~ADOC
        = Doc

        == First

        === Syntax

        == Second

        === Syntax
      ADOC

      core = parse_to_core(adoc)
      sections = core.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.length).to eq(2)

      first_sub = sections[0].children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      second_sub = sections[1].children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }

      expect(first_sub.id).to eq('_first_syntax')
      expect(second_sub.id).to eq('_second_syntax')
      expect(first_sub.id).not_to eq(second_sub.id)
    end

    it 'preserves explicit section IDs' do
      adoc = <<~ADOC
        = Doc

        [[custom-id]]
        == My Section
      ADOC

      core = parse_to_core(adoc)
      section = core.children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(section.id).to eq('custom-id')
    end
  end

  describe 'Fix 13: Inline whitespace between sentences' do
    it 'preserves whitespace between text elements separated by newlines' do
      adoc = <<~ADOC
        = Doc

        First sentence.
        Second sentence.
      ADOC

      core = parse_to_core(adoc)
      para = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      expect(para).not_to be_nil
      text = para.content.to_s
      expect(text).to include('First sentence.')
      expect(text).to include('Second sentence.')
    end
  end

  describe 'Fix 14: Definition list with anchor terms' do
    it 'renders definition list terms and definitions with anchors' do
      adoc = <<~ADOC
        = Doc

        [[my-term]]
        Term text:: Definition content
      ADOC

      core = parse_to_core(adoc)
      dlist = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dlist).not_to be_nil
      expect(dlist.items).not_to be_empty
      item = dlist.items.first
      expect(item.term).to include('Term text')
    end
  end

  # Regression: previously the `line_not_text?` predicate did not reject
  # `//`-prefixed lines, so the paragraph parser consumed `// tag::x[]`
  # and `// end::x[]` markers as plain text, producing phantom paragraphs
  # containing the tag markup.
  describe 'Fix 15: // comments and tag markers do not leak into paragraphs' do
    it 'drops // tag:: and // end:: lines instead of treating them as paragraphs' do
      adoc = <<~ADOC
        Before.

        // tag::tutorial[]
        Content.
        // end::tutorial[]

        After.
      ADOC

      core = parse_to_core(adoc)
      paragraphs = core.children.select { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      texts = paragraphs.map { |p| p.content.to_s.strip }

      expect(texts).to eq(%w[Before. Content. After.])
      expect(texts).not_to include(match(/tag::/))
      expect(texts).not_to include(match(/end::/))
    end
  end

  # Regression: `\<<` is the AsciiDoc escape for a literal `<<`. Without
  # a dedicated escape rule, the backslash was consumed as plain text and
  # the `<<` re-entered the cross-reference production, producing a link
  # to a non-existent anchor with garbage in the link text.
  describe 'Fix 16: \<< escape produces literal << without firing xref' do
    it 'does not produce a CrossReference for \\<<' do
      adoc = "Shows syntax: \\<<formulaB-1>> as text.\n"

      core = parse_to_core(adoc)
      inline = find_all_xrefs(core)
      expect(inline).to be_empty

      para = core.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      expect(para.content.to_s).to include('<<')
    end
  end

  # Regression: literal blocks (`....`) preserve their body byte-for-byte.
  # Previously they were routed through the paragraph-grouping code path,
  # which collapsed intra-block whitespace, joined consecutive non-blank
  # lines, and stripped leading indentation.
  describe 'Fix 17: literal block preserves whitespace and line structure' do
    it 'keeps newlines and indentation intact across the literal body' do
      adoc = <<~ADOC
        ....
        <clause id="test">
          <p>Content</p>
        </clause>
        ....
      ADOC

      core = parse_to_core(adoc)
      literal = core.children.find { |c| c.is_a?(Coradoc::CoreModel::LiteralBlock) }
      expect(literal).not_to be_nil
      expect(literal.content).to eq("<clause id=\"test\">\n  <p>Content</p>\n</clause>")
    end
  end

  # Regression: `image::file[Alt text]` requires the attribute-list parser
  # to accept spaces in the unquoted positional value. Previously the
  # charset rejected spaces, the block-image parser failed, and the line
  # fell through to paragraph parsing where `image:` matched as an inline
  # macro with a corrupted path.
  describe 'Fix 18: image:: block macro accepts alt text with spaces' do
    it 'parses as a top-level image with src and alt preserved' do
      adoc = <<~ADOC
        Para before.

        image::foo.png[Alt text]

        Para after.
      ADOC

      core = parse_to_core(adoc)
      images = []
      gather = lambda do |el|
        return unless el.is_a?(Coradoc::CoreModel::Base)

        images << el if el.is_a?(Coradoc::CoreModel::Image)
        if el.class.attributes.key?(:children) && el.children
          el.children.each { |c| gather.call(c) }
        end
      end
      gather.call(core)

      image = images.find { |i| i.src == 'foo.png' }
      expect(image).not_to be_nil
      expect(image.alt).to eq('Alt text')
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

    children = (el.children if el.is_a?(Coradoc::CoreModel::Base) && el.class.attributes.key?(:children) && el.children)

    children&.each { |c| xrefs.concat(find_all_xrefs(c)) }

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
