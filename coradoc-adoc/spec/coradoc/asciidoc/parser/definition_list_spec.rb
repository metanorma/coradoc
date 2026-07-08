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

  # Regression: previously the multi-line form (`term::\ndef`) produced a
  # different AST shape than the single-line form (`term:: def`), and the
  # transformer's fallback rule treated the multi-line shape as an array
  # of separate term/definition hashes — losing the term entirely.
  describe 'multi-line definition list form' do
    it 'preserves both term and definition for multi-line items' do
      core = parse_to_core(<<~ADOC)
        Software::
        The Metanorma toolchain.

        Document metamodels::
        Provides document structure.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl).not_to be_nil
      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('Software')
      expect(dl.items[0].definitions.first).to eq('The Metanorma toolchain.')
      expect(dl.items[1].term).to eq('Document metamodels')
      expect(dl.items[1].definitions.first).to eq('Provides document structure.')
    end

    it 'joins consecutive non-blank dd lines into one paragraph' do
      core = parse_to_core(<<~ADOC)
        Invalid XML::
        The XML file does not comply with the XML schema, or with the formatting rules
        defined by the SDO.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl).not_to be_nil
      expect(dl.items.length).to eq(1)
      expect(dl.items[0].term).to eq('Invalid XML')
      expect(dl.items[0].definitions.first)
        .to eq('The XML file does not comply with the XML schema, or with the formatting rules defined by the SDO.')
    end

    it 'captures `+`-continuation blocks as attached_children of the dd' do
      core = parse_to_core(<<~ADOC)
        Invalid XML::
        The XML file does not comply with the XML schema.
        +
        All errors are logged to the terminal and saved to an error file.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl).not_to be_nil
      expect(dl.items.length).to eq(1)
      item = dl.items[0]
      expect(item.term).to eq('Invalid XML')
      expect(item.definitions.first).to eq('The XML file does not comply with the XML schema.')
      expect(item.attached_children.length).to eq(1)
      expect(item.attached_children.first).to be_a(Coradoc::CoreModel::ParagraphBlock)
    end

    it 'captures multiple `+`-continuation blocks in source order' do
      core = parse_to_core(<<~ADOC)
        Term::
        First definition line.
        +
        First attached paragraph.
        +
        Second attached paragraph.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl.items[0].attached_children.length).to eq(2)
      expect(dl.items[0].attached_children).to all(be_a(Coradoc::CoreModel::ParagraphBlock))
    end
  end

  describe '`+`-continuation with block types' do
    it 'captures an open block (`--`) attached via `+`' do
      core = parse_to_core(<<~ADOC)
        Term::
        +
        --
        First paragraph inside open block.

        Second paragraph inside open block.
        --
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.attached_children.length).to eq(1)
      # Open block becomes a generic Block in CoreModel; verify it has
      # multiple paragraph children to confirm the open block content
      # was captured.
      attached = item.attached_children.first
      expect(attached).to respond_to(:children)
      expect(attached.children.length).to be >= 2
    end

    it 'captures an example block (`====`) attached via `+`' do
      core = parse_to_core(<<~ADOC)
        Term::
        Definition text.
        +
        .Example title
        ====
        Example content.
        ====
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.attached_children.length).to eq(1)
      expect(item.definitions.first).to eq('Definition text.')
    end

    it 'captures a source block (`----`) attached via `+`' do
      core = parse_to_core(<<~ADOC)
        Term::
        Definition.
        +
        [source,ruby]
        ----
        puts "hi"
        ----
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.attached_children.length).to eq(1)
      expect(item.attached_children.first).to be_a(Coradoc::CoreModel::SourceBlock)
    end

    it 'captures a NOTE admonition attached via `+`' do
      core = parse_to_core(<<~ADOC)
        Term::
        Definition.
        +
        NOTE: This is a note attached to the dd.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.attached_children.length).to eq(1)
      expect(item.attached_children.first).to be_a(Coradoc::CoreModel::AnnotationBlock)
    end
  end

  describe 'inline-form dd with hard break + continuation' do
    # Regression: text_line's text_any greedily crosses newlines via
    # hard_line_break, swallowing the next source line's content
    # (e.g. the `+` line-continuation marker). The custom
    # dlist_definition_line matcher prevents this.
    it 'does not swallow `+` after a hard break (` +`)' do
      core = parse_to_core(<<~ADOC)
        `:docnumber:`:: The ISO document number without any part. +
        +
        .Example of setting `:docnumber:`
        [example]
        ====
        For ISO 8601-1:2019, the docnumber is 8601.
        ====
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.term).to eq(':docnumber:')
      # Definition does NOT include the `+` marker or the example title.
      expect(item.definitions.first)
        .to match(/does not include `\+`/)
        .or eq('The ISO document number without any part.')
      # The example block is attached, not jammed into the definition.
      expect(item.attached_children.length).to eq(1)
    end

    it 'preserves the hard line break inside the dd text' do
      core = parse_to_core(<<~ADOC)
        `:docnumber:`:: First line. +
        Second line on same dd.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      # The hard break joins the two source lines into one definition;
      # downstream rendering emits a <br>.
      expect(item.definitions.first).to include('First line.')
      expect(item.definitions.first).to include('Second line')
    end
  end

  describe 'multi-level definition lists (`::` / `:::` / `::::`)' do
    it 'nests `:::` items under preceding `::` item' do
      core = parse_to_core(<<~ADOC)
        parent::
        parent def.

        child1::: child def1
        child2::: child def2
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl.items.length).to eq(1)
      parent = dl.items[0]
      expect(parent.term).to eq('parent')
      expect(parent.definitions.first).to eq('parent def.')
      expect(parent.nested).not_to be_nil
      expect(parent.nested.items.length).to eq(2)
      expect(parent.nested.items[0].term).to eq('child1')
      expect(parent.nested.items[1].term).to eq('child2')
    end

    it 'nests `::::` items under preceding `:::` item (3 levels deep)' do
      core = parse_to_core(<<~ADOC)
        l1::
        l1 def.

        l2::: l2 def.

        l3:::: l3 def.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl.items.length).to eq(1)
      l1 = dl.items[0]
      expect(l1.term).to eq('l1')
      expect(l1.nested.items.length).to eq(1)
      l2 = l1.nested.items[0]
      expect(l2.term).to eq('l2')
      expect(l2.nested.items.length).to eq(1)
      l3 = l2.nested.items[0]
      expect(l3.term).to eq('l3')
    end

    it 'returns to parent level after nested items' do
      core = parse_to_core(<<~ADOC)
        parent::
        parent def.

        child::: child def.

        sibling::
        sibling def.
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('parent')
      expect(dl.items[0].nested.items.length).to eq(1)
      expect(dl.items[1].term).to eq('sibling')
    end
  end

  describe 'term-only items with `+`-continuation' do
    it 'supports dd populated entirely via `+` (no inline def)' do
      core = parse_to_core(<<~ADOC)
        `:classification:`::
        +
        --
        First paragraph.

        Second paragraph.
        --
      ADOC

      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      item = dl.items[0]
      expect(item.term).to eq(':classification:')
      # No inline definition — definitions should be empty.
      expect(item.definitions).to be_empty
      # The open block is attached.
      expect(item.attached_children.length).to eq(1)
    end
  end

  describe 'multi-level nesting without blank-line separators' do
    # Regression for the original bug: parser used to greedily group
    # `parent::` and `child:::` (different delimiters) into one item
    # with concatenated terms. Each term MUST become its own item, with
    # nesting inferred from delimiter depth.
    it 'nests `:::` directly under preceding `::` (no blank line)' do
      core = parse_to_core("parent::\nchild:::\ngrandchild\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      parent = dl.items[0]
      expect(parent.term).to eq('parent')
      expect(parent.terms).to eq(['parent'])
      expect(parent.nested.items.length).to eq(1)
      child = parent.nested.items[0]
      expect(child.term).to eq('child')
      expect(child.definitions).to eq(['grandchild'])
    end

    it 'nests 3 levels without blank lines' do
      core = parse_to_core("root::\nmid:::\nleaf::::\ndeep\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      root = dl.items[0]
      expect(root.term).to eq('root')
      expect(root.nested.items.length).to eq(1)
      mid = root.nested.items[0]
      expect(mid.term).to eq('mid')
      expect(mid.nested.items.length).to eq(1)
      leaf = mid.nested.items[0]
      expect(leaf.term).to eq('leaf')
      expect(leaf.definitions).to eq(['deep'])
    end
  end

  describe 'multi-term `<dt>` (shared `<dd>`)' do
    # AsciiDoc form:
    #   term1::
    #   term2::
    #   shared definition
    # Both terms share one `<dd>`. CoreModel represents this as one
    # DefinitionItem with multiple entries in `terms`.
    it 'merges consecutive term-only items at the same depth' do
      core = parse_to_core("term1::\nterm2::\nshared def\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      item = dl.items[0]
      expect(item.terms).to eq(%w[term1 term2])
      expect(item.term).to eq('term1')
      expect(item.definitions).to eq(['shared def'])
    end

    it 'three terms share one dd' do
      core = parse_to_core("a::\nb::\nc::\ndef\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      expect(dl.items[0].terms).to eq(%w[a b c])
      expect(dl.items[0].definitions).to eq(['def'])
    end

    it 'does NOT merge across delimiter depth changes' do
      # parent:: and child::: have different delimiters — they should
      # nest, not merge into a multi-term item.
      core = parse_to_core("parent::\nchild:::\ngrandchild\n")
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      expect(dl.items[0].terms).to eq(['parent'])
      expect(dl.items[0].nested.items[0].terms).to eq(['child'])
    end

    it 'does NOT merge once the previous item has its own def' do
      # Once an item has its own def, it's the terminal dt of any
      # multi-term group. The next same-depth item starts a fresh entry.
      core = parse_to_core(<<~ADOC)
        first::
        first def
        second::
        second def
      ADOC
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('first')
      expect(dl.items[0].definitions).to eq(['first def'])
      expect(dl.items[1].term).to eq('second')
      expect(dl.items[1].definitions).to eq(['second def'])
    end

    it 'multi-term dt with `+`-continuation attaches block to merged item' do
      core = parse_to_core(<<~ADOC)
        term1::
        term2::
        shared def
        +
        attached paragraph
      ADOC
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      item = dl.items[0]
      expect(item.terms).to eq(%w[term1 term2])
      expect(item.definitions).to eq(['shared def'])
      expect(item.attached_children.length).to eq(1)
    end
  end

  describe 'mixed: multi-level + multi-term + continuation' do
    it 'parent with multi-term child item' do
      core = parse_to_core(<<~ADOC)
        parent::
        parent def

        child1:::
        child2:::
        shared child def
      ADOC
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      parent = dl.items[0]
      expect(parent.term).to eq('parent')
      expect(parent.nested.items.length).to eq(1)
      child = parent.nested.items[0]
      expect(child.terms).to eq(%w[child1 child2])
      expect(child.definitions).to eq(['shared child def'])
    end

    it 'continuation attaches to the deepest open item' do
      core = parse_to_core(<<~ADOC)
        parent::
        child:::
        +
        attached to child
        +
        another attached to child
      ADOC
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(1)
      parent = dl.items[0]
      expect(parent.attached_children.length).to eq(0)
      expect(parent.nested.items.length).to eq(1)
      child = parent.nested.items[0]
      expect(child.attached_children.length).to eq(2)
    end

    it 'return to parent level after nested + attached' do
      core = parse_to_core(<<~ADOC)
        parent::
        child:::
        child def
        +
        child attached

        sibling::
        sibling def
      ADOC
      dl = core.children.find { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }

      expect(dl.items.length).to eq(2)
      expect(dl.items[0].term).to eq('parent')
      expect(dl.items[0].nested.items.length).to eq(1)
      expect(dl.items[1].term).to eq('sibling')
      expect(dl.items[1].definitions).to eq(['sibling def'])
    end
  end
end
