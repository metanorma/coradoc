# frozen_string_literal: true

require_relative '../spec_helper'
require 'coradoc/asciidoc'

# Conformance tests drawn directly from
# docs/_references/markdown-serialization-spec.adoc §"Conformance test suite".
#
# These specs are the source of truth for the serializer's contract with
# the rest of the project. Any change that breaks one of these tests is a
# regression — not a flaky test.
RSpec.describe 'Markdown Serialization Spec — conformance' do
  def adoc_to_md(adoc_source)
    core = Coradoc.parse(adoc_source, format: :asciidoc)
    md_doc = Coradoc::Markdown.from_core_model(core)
    Coradoc::Markdown::Serializer.call(md_doc)
  end

  describe 'Section preserves body content' do
    it 'preserves section body content' do
      md = adoc_to_md("== Title\n\nParagraph text.")
      expect(md).to include('Paragraph text.')
    end
  end

  describe 'Flat definition list' do
    it 'preserves flat definition lists' do
      md = adoc_to_md("term1:: def1\nterm2:: def2\n")
      expect(md).to include('term1')
      expect(md).to include('def1')
    end
  end

  describe 'Nested definition list' do
    it 'preserves nested definition lists' do
      source = <<~ADOC
        == Section

        `parent`:: parent def

        `child1`::: child def 1
        `child2`::: child def 2
      ADOC
      md = adoc_to_md(source)
      expect(md).to include('parent')
      expect(md).to include('child def 1')
      expect(md).to include('child def 2')
    end
  end

  describe 'Admonition type preserved' do
    it 'preserves admonition type' do
      md = adoc_to_md("NOTE: This is a note.\n")
      expect(md).to match(/NOTE/i)
      expect(md).to include('This is a note.')
    end
  end

  describe 'Comment suppressed' do
    it 'suppresses comments from output' do
      source = "Paragraph one.\n\n// editorial comment\n\nParagraph two.\n"
      md = adoc_to_md(source)
      expect(md).not_to include('editorial comment')
      expect(md).not_to include('<!--')
    end
  end

  describe 'Bare URL uses autolink' do
    it 'serializes bare URLs as autolinks' do
      md = adoc_to_md("See https://example.com for info.\n")
      expect(md).not_to match(/\[https:\/\/example\.com\]\(/)
      expect(md).to include('https://example.com')
    end
  end

  describe 'Paragraph line joining' do
    it 'joins paragraph lines with spaces' do
      md = adoc_to_md("First line.\nSecond line.\n")
      expect(md).to include('First line. Second line.')
      expect(md).not_to include('line.Second')
    end
  end

  describe 'Example block caption preserved' do
    it 'preserves example block captions' do
      source = <<~ADOC
        .Example caption
        [example]
        ====
        Example content.
        ====
      ADOC
      md = adoc_to_md(source)
      expect(md).to include('Example caption')
      expect(md).to include('Example content.')
    end
  end

  describe 'Multi-line definition list item' do
    it 'preserves multi-line definition list items' do
      source = "term:: Definition starts here.\n+\nSecond line.\n"
      md = adoc_to_md(source)
      expect(md).to include('term')
      expect(md).to include('Definition starts here.')
      expect(md).to include('Second line.')
    end
  end

  describe 'Open block children preserved' do
    it 'preserves open block children' do
      source = <<~ADOC
        --
        First paragraph.

        Second paragraph.
        --
      ADOC
      md = adoc_to_md(source)
      expect(md).to include('First paragraph.')
      expect(md).to include('Second paragraph.')
    end
  end
end
