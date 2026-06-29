# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'coradoc/asciidoc'

# Asciidoctor does not permit `.Title` block-title lines on sections — the
# section heading IS its title. When `.Foo` precedes `== Heading`, the
# correct parse is an orphan `.Foo` paragraph (or discarded block title)
# followed by a clean section. Before this fix, `section_block` reused
# `block_header` (which includes `block_title.maybe`), so both `block_title`
# and `section_title` fired inside the same rule, both capturing the
# Parslet key `:title`. Parslet's hash merge silently dropped one and
# emitted its "Duplicate subtrees while merging result … (keys: [:title])"
# warning — visible data loss with a stderr signal.
#
# Coverage below locks in:
#   * The warning no longer fires for `.Foo\n== Heading` (or `...`).
#   * The orphan block title survives as a paragraph in the document.
#   * The section is still parsed with the correct heading.
#   * Legitimate section headers (`[[id]]`, `[role=x]`) still work.
#   * Block titles on actual blocks (source, example, etc.) are unaffected.
RSpec.describe 'Block title no longer collides with section title', :asciidoc do
  let(:captured_stderr) { StringIO.new }

  # Parslet writes the "Duplicate subtrees" warning to $stderr. Capture it
  # so the spec can assert on the absence of the warning without polluting
  # the test run's real stderr.
  def parse_quietly(adoc)
    original = $stderr
    $stderr = captured_stderr
    Coradoc.parse(adoc, format: :asciidoc)
  ensure
    $stderr = original
  end

  def child_classes(doc)
    doc.children.map(&:class)
  end

  describe 'reported bug: `.Foo` before section header' do
    let(:adoc) { ".Foo\n\n== Section\n\nbody\n" }
    let(:doc) { parse_quietly(adoc) }

    it 'does not emit the Duplicate-subtrees warning' do
      expect(captured_stderr.string).not_to include('Duplicate subtrees')
    end

    it 'produces two top-level children (orphan title + section)' do
      expect(doc.children.length).to eq(2)
    end

    it 'emits the orphan `.Foo` as a paragraph block' do
      expect(doc.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
    end

    it 'still parses the section with the correct title', :aggregate_failures do
      section = doc.children[1]
      expect(section).to be_a(Coradoc::CoreModel::SectionElement)
      expect(section.title).to eq('Section')
    end

    it 'does not attach the block title to the section' do
      expect(doc.children[1].title).to eq('Section')
    end
  end

  describe '`...` triple-dot edge case' do
    # `...` triggers the bug because `.` matches the block-title marker
    # and `..` becomes the title text. With the fix, the parser no longer
    # admits a block title here either.
    it 'does not emit the Duplicate-subtrees warning' do
      parse_quietly("...\n\n== Section\n\nbody\n")
      expect(captured_stderr.string).not_to include('Duplicate subtrees')
    end
  end

  describe 'legitimate section headers (regression guard)' do
    def first_section(adoc)
      parse_quietly(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
    end

    it 'parses a section with [[id]] anchor', :aggregate_failures do
      section = first_section("[[my-id]]\n== Section\n\nbody\n")
      expect(section).to be_a(Coradoc::CoreModel::SectionElement)
      expect(section.title).to eq('Section')
    end

    it 'parses a section with [#id] shorthand anchor' do
      section = first_section("[#my-id]\n== Section\n\nbody\n")
      expect(section).to be_a(Coradoc::CoreModel::SectionElement)
    end

    it 'parses a section with [role=x] attribute list' do
      section = first_section("[role=appendix]\n== Appendix\n\nbody\n")
      expect(section.title).to eq('Appendix')
    end

    it 'parses a section with [appendix] style marker' do
      section = first_section("[appendix]\n== Appendix\n\nbody\n")
      expect(section.title).to eq('Appendix')
    end

    it 'parses a section with both anchor and role' do
      section = first_section("[[sec-1]]\n[role=x]\n== Section\n\nbody\n")
      expect(section.title).to eq('Section')
    end

    it 'does not emit warnings for any of the legitimate header forms' do
      parse_quietly("[[id]]\n[role=x]\n== Section\n\nbody\n")
      expect(captured_stderr.string).not_to include('Duplicate subtrees')
    end
  end

  describe 'block titles on real blocks (regression guard)' do
    def first_block(adoc)
      parse_quietly(adoc).children.first
    end

    it 'still attaches `.Title` to a source block', :aggregate_failures do
      block = first_block(".My Title\n----\ncode\n----\n")
      expect(block).to be_a(Coradoc::CoreModel::SourceBlock)
      expect(block.title).to eq('My Title')
    end

    it 'still attaches `.Title` to an example block', :aggregate_failures do
      block = first_block(".Example\n====\nbody\n====\n")
      expect(block).to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(block.title).to eq('Example')
    end

    it 'still attaches `.Title` to a quote block', :aggregate_failures do
      block = first_block(".Quoted\n____\nbody\n____\n")
      expect(block).to be_a(Coradoc::CoreModel::QuoteBlock)
      expect(block.title).to eq('Quoted')
    end
  end
end
