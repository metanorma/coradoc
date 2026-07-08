# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/plugin/kotoshu'

# Lock down TextExtractor's per-CoreModel-type dispatch. Each visited
# type must produce the expected span shape (element label + text). If
# a new CoreModel type is added and `visit_any` doesn't have a branch
# for it, `visit_unknown` raises ArgumentError — caught at the spec
# boundary, not silently swallowed.
RSpec.describe 'TextExtractor per-type dispatch' do
  let(:extractor) { Coradoc::Plugin::Kotoshu::TextExtractor }

  def extract_single(adoc)
    doc = Coradoc.parse(adoc, format: :asciidoc)
    extractor.extract(doc, source: adoc)
  end

  describe 'block-level prose types' do
    it 'extracts a paragraph as element=paragraph' do
      spans = extract_single("Real prose here.\n")
      para = spans.find { |s| s.element == 'paragraph' }
      expect(para.text).to eq('Real prose here.')
    end

    it 'extracts a section title with the section label' do
      spans = extract_single("== My Section\n\nbody.\n")
      section_titles = spans.select { |s| s.section == 'My Section' }
      expect(section_titles).not_to be_empty
    end

    it 'extracts list items with element=list_item' do
      spans = extract_single("* one\n* two\n")
      items = spans.select { |s| s.element == 'list_item' }.map(&:text)
      expect(items).to include('one', 'two')
    end

    it 'extracts table cells with element=table_cell' do
      spans = extract_single("|===\n| a | b\n|===\n")
      cells = spans.select { |s| s.element == 'table_cell' }.map(&:text)
      expect(cells).to include('a', 'b')
    end

    it 'extracts a definition term' do
      spans = extract_single("Term::\n definition\n")
      term = spans.find { |s| s.element == 'definition_term' }
      expect(term.text).to eq('Term')
    end
  end

  describe 'prose? = false blocks (skipped)' do
    it 'skips SourceBlock content' do
      spans = extract_single("[source,ruby]\n----\nmisspelled_should_be_skippedd\n----\n")
      expect(spans.map(&:text)).not_to include('misspelled_should_be_skippedd')
    end

    it 'skips ListingBlock content' do
      spans = extract_single("----\nliteral_content_xyzabc\n----\n")
      expect(spans.map(&:text)).not_to include('literal_content_xyzabc')
    end

    it 'skips LiteralBlock content' do
      spans = extract_single("....\nliteral_misspelled_content_xyzabc\n....\n")
      expect(spans.map(&:text)).not_to include('literal_misspelled_content_xyzabc')
    end

    it 'skips CommentBlock content' do
      spans = extract_single("////\ncomment misspelled xyzabc\n////\n")
      expect(spans.map(&:text)).not_to include(/comment misspelled xyzabc/)
    end

    it 'skips PassBlock content' do
      spans = extract_single("++++\npass_through_content_xyz\n++++\n")
      expect(spans.map(&:text)).not_to include('pass_through_content_xyz')
    end
  end

  describe 'metadata filtering' do
    it 'skips document header attribute lines' do
      spans = extract_single("= Title\nAuthor <a@b.com>\n:toc:\n:lang: en\n\nbody.\n")
      # body paragraph should be extracted; :toc: and author should not
      expect(spans.map(&:text)).to include('body.')
      expect(spans.map(&:text)).not_to include(':toc:')
    end
  end

  describe 'admonition and quote blocks (prose-bearing)' do
    it 'extracts NOTE admonition content' do
      spans = extract_single("[NOTE]\n====\nThis note recieves misspelling.\n====\n")
      expect(spans.map(&:text)).to include('This note recieves misspelling.')
    end

    it 'extracts quote block content' do
      spans = extract_single("____\nquoted prose here\n____\n")
      expect(spans.map(&:text).join).to include('quoted prose here')
    end
  end

  describe 'unregistered types raise (visit_unknown)' do
    # If a new CoreModel class is added without a visit_* branch,
    # TextExtractor fails loudly rather than silently skipping.
    it 'raises ArgumentError for an unregistered CoreModel class' do
      imaginary_class = Class.new(Coradoc::CoreModel::Base)
      stub_const('Coradoc::CoreModel::ImaginaryTestNode', imaginary_class)
      doc = Coradoc::CoreModel::DocumentElement.new(children: [imaginary_class.new])
      expect do
        Coradoc::Plugin::Kotoshu::TextExtractor.extract(doc)
      end.to raise_error(ArgumentError, /ImaginaryTestNode/)
    end
  end
end
