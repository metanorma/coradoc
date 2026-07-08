# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::Plugin::Kotoshu::TextExtractor do
  describe '.extract' do
    it 'yields a span for each paragraph' do
      spans = extract(<<~ADOC)
        = Title

        First paragraf.

        Second paragraf.
      ADOC
      paragraphs = spans.select { |s| s.element == 'paragraph' }
      expect(paragraphs.map(&:text)).to include('First paragraf.')
      expect(paragraphs.map(&:text)).to include('Second paragraf.')
    end

    it 'skips source code blocks' do
      spans = extract(<<~ADOC)
        Before code.

        [source,ruby]
        ----
        misspelledword_should_be_skippedd
        ----

        After code.
      ADOC
      texts = spans.map(&:text)
      expect(texts).not_to include('misspelledword_should_be_skippedd')
      expect(texts).to include('Before code.')
      expect(texts).to include('After code.')
    end

    it 'skips listing and literal blocks' do
      spans = extract(<<~ADOC)
        Before.

        ....
        literal_misspelled_content_xyzabc
        ....

        After.
      ADOC
      texts = spans.map(&:text)
      expect(texts).not_to include('literal_misspelled_content_xyzabc')
    end

    it 'extracts list items' do
      spans = extract(<<~ADOC)
        * Item oneo
        * Item twoo
      ADOC
      list_items = spans.select { |s| s.element == 'list_item' }.map(&:text)
      expect(list_items).to include('Item oneo')
      expect(list_items).to include('Item twoo')
    end

    it 'extracts table cells' do
      spans = extract(<<~ADOC)
        |===
        | Header A | Header Bee
        | celll one
        | celll twoo
        |===
      ADOC
      cells = spans.select { |s| s.element == 'table_cell' }.map(&:text)
      expect(cells.join).to include('celll one')
      expect(cells.join).to include('celll twoo')
    end

    it 'skips document header author and attribute lines' do
      spans = extract(<<~ADOC)
        = Title
        Author Name <author@example.com>
        :toc:
        :lang: en

        Body paragraph.
      ADOC
      texts = spans.map(&:text)
      expect(texts).not_to include('Author Name <author@example.com>')
      expect(texts).not_to include(':toc:')
      expect(texts).not_to match(/:lang: en/)
    end

    it 'extracts note/admonition block content' do
      spans = extract(<<~ADOC)
        [NOTE]
        ====
        This note recieve misspelling.
        ====
      ADOC
      note_texts = spans.map(&:text)
      expect(note_texts).to include('This note recieve misspelling.')
    end

    it 'tags each span with the enclosing section title' do
      spans = extract(<<~ADOC)
        = Document Title

        Preamble text.

        == My Section

        Section body text.
      ADOC
      section_spans = spans.select { |s| s.section == 'My Section' }
      expect(section_spans.map(&:text)).to include('Section body text.')
    end

    it 'computes a 1-based line hint from the source' do
      source = <<~ADOC
        = Title

        First paragraph.

        Second paragraph on line five.
      ADOC
      spans = extract(source)
      second = spans.find { |s| s.text.include?('Second paragraph') }
      expect(second.line_hint).to eq(5)
    end

    it 'prefers node.source_line over source-text scanning when both are available' do
      # When the parser populates source_line on the node, the extractor
      # uses it directly — more accurate than probe-token scanning and
      # survives cases where the probe token appears on multiple lines.
      source = "= Title\n\nUniqueParaTextHere on line three.\n"
      spans = extract(source)
      span = spans.find { |s| s.text.include?('UniqueParaTextHere') }
      expect(span.line_hint).to eq(3)
    end

    it 'returns nil line hint when source is not provided' do
      doc = Coradoc.parse(<<~ADOC, format: :asciidoc)
        Body paragraph.
      ADOC
      spans = described_class.extract(doc)
      expect(spans.first.line_hint).to be_nil
    end

    it 'returns empty array for empty document' do
      doc = Coradoc.parse('', format: :asciidoc)
      expect(described_class.extract(doc)).to eq([])
    end
  end

  def extract(source)
    doc = Coradoc.parse(source, format: :asciidoc)
    described_class.extract(doc, source: source)
  end
end
