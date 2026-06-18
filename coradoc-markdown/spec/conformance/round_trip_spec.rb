# frozen_string_literal: true

# Round-trip conformance: every Markdown surface we emit must re-parse
# to an equivalent CoreModel. A failure here is either a serializer
# bug (we emit invalid Markdown) or a parser/transformer bug (we
# cannot read back what we wrote). Both must be fixed at the source —
# never papered over in the serializer.
require_relative '../spec_helper'

RSpec.describe 'Markdown serialization round-trip', :aggregate_failures do
  def roundtrip(markdown)
    doc1    = Coradoc::Markdown.parse(markdown)
    core1   = Coradoc::Markdown.to_core_model(doc1)
    out     = Coradoc::Markdown.from_core_model(core1)
    text2   = Coradoc::Markdown.serialize(out)
    core2   = Coradoc::Markdown.parse_to_core(text2)
    [core1, core2, text2]
  end

  def flatten_text(core)
    Array(core.children).map { |c| c.respond_to?(:flat_text) ? c.flat_text.to_s : c.to_s }.join("\n")
  end

  describe 'block elements' do
    it 'round-trips a paragraph' do
      c1, c2, = roundtrip("Hello world.\n")
      expect(c2.children.size).to eq(c1.children.size)
      expect(flatten_text(c2)).to include('Hello world.')
    end

    it 'round-trips an ATX heading' do
      _c1, c2, text2 = roundtrip("# Title\n\nBody.\n")
      expect(text2).to include('# Title')
      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.flat_map { |s| [s.title, Array(s.children).map(&:flat_text).join] }.join).to include('Title')
    end

    it 'round-trips an unordered list' do
      _c1, c2, text2 = roundtrip("- one\n- two\n- three\n")
      expect(text2).to include('- one')
      expect(text2).to include('- three')
      # Re-parsed model should have a ListBlock with 3 items
      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.size).to eq(1)
      expect(lists.first.items.size).to eq(3)
    end

    it 'round-trips a nested unordered list (2-deep)' do
      _c1, c2, text2 = roundtrip("- outer\n    - inner\n")
      expect(text2).to include('- outer')
      expect(text2).to include('    - inner')
      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.size).to eq(1)
      expect(lists.first.items.size).to eq(1)
      nested = lists.first.items.first.nested_list
      expect(nested).not_to be_nil
      expect(nested.items.size).to eq(1)
      expect(nested.items.first.content).to include('inner')
    end

    it 'round-trips a GFM task list' do
      [
        ['- [ ] todo', false],
        ['- [x] done', true]
      ].each do |(src, checked)|
        _c1, c2, text2 = roundtrip("#{src}\n")
        expect(text2).to include(src), "expected #{src.inspect} to survive"
        lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
        expect(lists.size).to eq(1)
        expect(lists.first.items.size).to eq(1)
      end
    end

    it 'round-trips an ordered list' do
      _c1, c2, text2 = roundtrip("1. first\n2. second\n")
      expect(text2).to include('first')
      expect(text2).to include('second')
      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.first.marker_type).to eq('ordered')
    end

    it 'round-trips a fenced code block' do
      _c1, c2, text2 = roundtrip("```ruby\nputs 1\n```\n")
      expect(text2).to include('```ruby')
      expect(text2).to include('puts 1')
      expect(flatten_text(c2)).to include('puts 1')
    end

    it 'round-trips a blockquote' do
      _c1, c2, text2 = roundtrip("> quoted text\n")
      expect(text2).to start_with('> ')
      expect(flatten_text(c2)).to include('quoted text')
    end

    it 'round-trips a GFM table' do
      _c1, c2, text2 = roundtrip("| H1 | H2 |\n| --- | --- |\n| a | b |\n")
      expect(text2).to include('| H1 | H2 |')
      expect(text2).to include('| a | b |')
      tables = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::Table) }
      expect(tables.size).to eq(1)
    end

    it 'round-trips an image' do
      _c1, c2, text2 = roundtrip("![alt text](image.png)\n")
      expect(text2).to include('![alt text](image.png)')
      expect(flatten_text(c2)).to include('image.png')
    end

    it 'round-trips a horizontal rule' do
      _c1, c2, text2 = roundtrip("a\n\n---\n\nb\n")
      expect(text2).to include("\n---\n")
      expect(flatten_text(c2)).to include('a')
      expect(flatten_text(c2)).to include('b')
    end
  end

  describe 'inline elements' do
    it 'round-trips a link' do
      _c1, c2, text2 = roundtrip("[text](https://example.com)\n")
      expect(text2).to include('[text](https://example.com)')
      expect(flatten_text(c2)).to include('text')
      expect(flatten_text(c2)).to include('example.com')
    end

    it 'round-trips an angle autolink' do
      _c1, c2, text2 = roundtrip("<https://example.com>\n")
      expect(text2).to include('https://example.com')
      expect(flatten_text(c2)).to include('example.com')
    end

    it 'round-trips strong/emphasis/code' do
      [
        "**bold**",
        "*italic*",
        "`code`",
        "~~strike~~",
        "==highlight=="
      ].each do |inline|
        _c1, c2, text2 = roundtrip("#{inline} text\n")
        expect(text2).to include(inline), "expected #{inline.inspect} to survive"
        expect(flatten_text(c2)).to include('text')
      end
    end

    it 'round-trips a paragraph with mixed inline elements' do
      _c1, c2, text2 = roundtrip("Hello **bold** and *italic* and `code` end.\n")
      expect(text2).to include('**bold**')
      expect(text2).to include('*italic*')
      expect(text2).to include('`code`')
      expect(flatten_text(c2)).to include('Hello')
      expect(flatten_text(c2)).to include('end.')
    end

    it 'round-trips a footnote reference + definition' do
      _c1, c2, text2 = roundtrip("see [^1].\n\n[^1]: note text\n")
      expect(text2).to include('[^1]')
      expect(text2).to include('[^1]: note text')
      footnotes = []
      walk = ->(node) do
        case node
        when Coradoc::CoreModel::Footnote then footnotes << node
        when Coradoc::CoreModel::Base then Array(node.children).each { |c| walk.call(c) }
        when Array then node.each { |c| walk.call(c) }
        end
      end
      walk.call(c2)
      expect(footnotes.map(&:content).join).to include('note text')
    end

    it 'round-trips a definition list (flat)' do
      _c1, c2, text2 = roundtrip("term\n: definition\n")
      expect(text2).to include('term')
      expect(text2).to include(': definition')
      dls = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::DefinitionList) }
      expect(dls.size).to eq(1)
    end
  end

  describe 'full document' do
    it 'round-trips a mixed-source document' do
      src = <<~MD
        # Heading One

        Paragraph with **bold** and *italic* and `code`.

        - list item one
        - list item two

        ## Subheading

        > blockquote text

        ```ruby
        puts "hi"
        ```
      MD

      c1, c2, text2 = roundtrip(src)

      # Serializer output should contain the same content
      expect(text2).to include('# Heading One')
      expect(text2).to include('**bold**')
      expect(text2).to include('- list item one')
      expect(text2).to include('## Subheading')
      expect(text2).to include('> blockquote text')
      expect(text2).to include('puts "hi"')

      # Re-parsed model should preserve structural variety
      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.map(&:title)).to include('Heading One')
      expect(sections.map(&:title)).to include('Subheading')

      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      list_text = lists.flat_map { |l| l.items.map(&:flat_text) }.join
      expect(list_text).to include('list item one')

      expect(c2.children.any? { |c| c.is_a?(Coradoc::CoreModel::QuoteBlock) }).to be(true)
      expect(c2.children.any? { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }).to be(true)
    end
  end

  describe 'alternate syntaxes' do
    it 'round-trips a setext level-1 heading (====)' do
      _c1, c2, text2 = roundtrip("Title\n=====\n\nBody.\n")
      expect(text2).to include('# Title')
      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.first.level).to eq(1)
      expect(sections.first.title).to eq('Title')
    end

    it 'round-trips a setext level-2 heading (----)' do
      _c1, c2, text2 = roundtrip("Sub\n-----\n\nBody.\n")
      expect(text2).to include('## Sub')
      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.first.level).to eq(2)
    end

    it 'round-trips a fenced code block without a language' do
      _c1, c2, text2 = roundtrip("```\nplain code\n```\n")
      expect(text2).to start_with('```')
      blocks = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(blocks.first.flat_text).to include('plain code')
    end

    it 'round-trips a multi-paragraph blockquote' do
      _c1, c2, text2 = roundtrip("> para one\n>\n> para two\n")
      expect(text2).to include('para one')
      expect(text2).to include('para two')
      quotes = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::QuoteBlock) }
      expect(quotes.size).to eq(1)
    end

    it 'round-trips a block math expression' do
      _c1, c2, text2 = roundtrip("$$\nx = y\n$$\n")
      expect(text2).to include('$$')
      expect(text2).to include('x = y')
      # The re-parse should yield some block carrying the math content
      content = c2.children.map { |c| c.respond_to?(:content) ? c.content.to_s : c.flat_text.to_s }.join
      expect(content).to include('x = y')
    end

    it 'round-trips inline math' do
      _c1, c2, text2 = roundtrip("inline $a + b$ math\n")
      expect(text2).to include('$a + b$')
      expect(text2).to include('inline')
    end

    it 'round-trips an image with a title' do
      _c1, c2, text2 = roundtrip("![alt](img.png \"Title\")\n")
      expect(text2).to include('![alt](img.png "Title")')
      expect(text2).to include('img.png')
    end

    it 'round-trips a link with a title' do
      _c1, c2, text2 = roundtrip("[text](https://example.com \"Site\")\n")
      expect(text2).to include('[text](https://example.com "Site")')
    end

    it 'round-trips a horizontal rule (asterisk form)' do
      _c1, c2, text2 = roundtrip("a\n\n***\n\nb\n")
      expect(text2).to match(/^-{3,}$|^\*{3,}$|^_{3,}$/)
      expect(c2.children.map(&:flat_text).join).to include('a')
      expect(c2.children.map(&:flat_text).join).to include('b')
    end
  end

end
