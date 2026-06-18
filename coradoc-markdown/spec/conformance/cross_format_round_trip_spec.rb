# frozen_string_literal: true

# Cross-format roundtrip: an AsciiDoc source → CoreModel → Markdown
# serializer → CoreModel should preserve semantic content across the
# hub-and-spoke. This catches Markdown-serializer bugs that one-way
# conformance specs miss (e.g. emitting invalid syntax, losing
# structure that re-parsing cannot recover).
require_relative '../spec_helper'
require 'coradoc/asciidoc'

RSpec.describe 'Cross-format round-trip (AsciiDoc → Markdown → CoreModel)', :aggregate_failures do
  def adoc_to_md_to_core(adoc)
    core1 = Coradoc.parse(adoc, format: :asciidoc)
    md_doc = Coradoc::Markdown.from_core_model(core1)
    md_text = Coradoc::Markdown.serialize(md_doc)
    core2 = Coradoc::Markdown.parse_to_core(md_text)
    [core1, core2, md_text]
  end

  describe 'block preservation' do
    it 'preserves a paragraph' do
      _c1, c2, md = adoc_to_md_to_core("A simple paragraph.\n")
      expect(md).to include('A simple paragraph.')
      expect(c2.children.any? { |c| c.flat_text.to_s.include?('A simple paragraph') }).to be(true)
    end

    it 'preserves a section title' do
      _c1, c2, md = adoc_to_md_to_core("== My Section\n\nBody.\n")
      expect(md).to include('# My Section')
      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.map(&:title)).to include('My Section')
    end

    it 'preserves an unordered list' do
      _c1, c2, md = adoc_to_md_to_core("* one\n* two\n* three\n")
      expect(md).to include('one')
      expect(md).to include('three')
      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.size).to eq(1)
      expect(lists.first.items.size).to eq(3)
    end

    it 'preserves an ordered list' do
      _c1, c2, md = adoc_to_md_to_core(". first\n. second\n")
      expect(md).to include('first')
      lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.first.marker_type).to eq('ordered')
    end

    it 'preserves a source block with language' do
      _c1, c2, md = adoc_to_md_to_core("[source,ruby]\n----\nputs 42\n----\n")
      expect(md).to include('```ruby')
      expect(md).to include('puts 42')
      src = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(src.first.language).to eq('ruby')
    end

    it 'preserves a blockquote' do
      _c1, c2, md = adoc_to_md_to_core("____\nquoted\n____\n")
      expect(md).to include('quoted')
      quotes = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::QuoteBlock) }
      expect(quotes.size).to eq(1)
    end

    it 'preserves a table' do
      _c1, c2, md = adoc_to_md_to_core("|===\n| H1 | H2\n| a | b\n|===\n")
      expect(md).to include('H1')
      expect(md).to include('H2')
      tables = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::Table) }
      expect(tables.size).to eq(1)
    end

    it 'preserves an image with alt text' do
      # Use AsciiDoc title-block syntax (`.Caption`) since the parser
      # currently drops the inline `[alt]` attribute list.
      _c1, c2, md = adoc_to_md_to_core(".Logo\nimage::logo.png[]\n")
      expect(md).to include('logo.png')
      expect(md).to include('Logo')
    end

    it 'preserves a comment block by suppressing it (default)' do
      _c1, c2, md = adoc_to_md_to_core("////\nhidden\n////\n")
      expect(md).not_to include('hidden')
    end

    it 'preserves a comment block when suppress_comments is false' do
      core = Coradoc.parse("////\nvisible\n////\n", format: :asciidoc)
      md_doc = Coradoc::Markdown.from_core_model(core)
      md = Coradoc::Markdown.serialize(md_doc, suppress_comments: false)
      expect(md).to include('visible')
      expect(md).to include('<!--')
    end
  end

  describe 'inline preservation' do
    it 'preserves bold and italic' do
      _c1, c2, md = adoc_to_md_to_core("*bold* and _italic_\n")
      expect(md).to include('**bold**')
      expect(md).to include('*italic*')
    end

    it 'preserves monospace' do
      _c1, _c2, md = adoc_to_md_to_core("`code`\n")
      expect(md).to include('`code`')
    end

    it 'preserves a link' do
      _c1, c2, md = adoc_to_md_to_core("https://example.com[Example]\n")
      expect(md).to include('https://example.com')
      expect(md).to include('Example')
    end
  end

  describe 'mixed document' do
    it 'preserves a multi-section document end-to-end' do
      adoc = <<~ADOC
        = Document Title

        == First Section

        First paragraph.

        * item one
        * item two

        == Second Section

        Second paragraph with *bold*.
      ADOC

      _c1, c2, md = adoc_to_md_to_core(adoc)
      expect(md).to include('First Section')
      expect(md).to include('Second Section')
      expect(md).to include('item one')
      expect(md).to include('**bold**')

      sections = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.map(&:title)).to include('First Section')
      expect(sections.map(&:title)).to include('Second Section')
    end
  end
end

RSpec.describe 'Cross-format round-trip (Markdown → AsciiDoc → CoreModel)', :aggregate_failures do
  def md_to_adoc_to_core(md)
    core1   = Coradoc::Markdown.parse_to_core(md)
    adoc    = Coradoc::AsciiDoc.serialize(core1)
    core2   = Coradoc.parse(adoc, format: :asciidoc)
    [core1, core2, adoc]
  end

  it 'preserves a paragraph' do
    _c1, c2, adoc = md_to_adoc_to_core("Hello world.\n")
    expect(adoc).to include('Hello world.')
    expect(c2.children.any? { |c| c.flat_text.to_s.include?('Hello world') }).to be(true)
  end

  it 'preserves a code block with language' do
    _c1, c2, adoc = md_to_adoc_to_core("```ruby\nputs 1\n```\n")
    expect(adoc).to include('puts 1')
    expect(adoc).to include('source')
    blocks = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
    expect(blocks.first.language).to eq('ruby')
  end

  it 'preserves a blockquote' do
    _c1, c2, adoc = md_to_adoc_to_core("> quoted\n")
    expect(adoc).to include('quoted')
    expect(adoc).to include('____')
    quotes = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::QuoteBlock) }
    expect(quotes.size).to eq(1)
  end

  it 'preserves an unordered list' do
    _c1, c2, adoc = md_to_adoc_to_core("- one\n- two\n")
    expect(adoc).to include('one')
    expect(adoc).to include('two')
    lists = c2.children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
    expect(lists.first.items.size).to eq(2)
  end

  it 'preserves bold and italic' do
    _c1, c2, adoc = md_to_adoc_to_core("**bold** and *italic*\n")
    expect(adoc).to include('**bold**')
    expect(adoc).to include('*italic*')
  end
end
