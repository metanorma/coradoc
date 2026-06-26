# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'

# References the visitor's dispatch table so the spec helper recurses
# through exactly the same paths the visitor does. Subclasses (e.g.
# ParagraphBlock < Block) are matched by +is_a?+, mirroring the
# visitor — see +container_reader_for+ below.
CONTAINER_TYPES = Coradoc::LinkRewriter::Visitor::CONTAINER_TYPES

RSpec.describe Coradoc::LinkRewriter do
  let(:adoc) do
    <<~ADOC
      = Doc

      See link:foo_bar.adoc[Foo] and <<section_two>>.

      [source,ruby]
      ----
      # link:do_not_touch.adoc inside source
      url = "xref:also_do_not_touch"
      ----
    ADOC
  end

  let(:document) { Coradoc.parse(adoc, format: :asciidoc) }

  describe '.rewrite with Identity (default)' do
    it 'returns a structurally equal document' do
      rewritten = described_class.rewrite(document)

      expect(rewritten.children.map(&:class)).to eq(document.children.map(&:class))
      expect(rewritten.semantically_equivalent?(document)).to be true
    end

    it 'returns a NEW object, never the same instance' do
      rewritten = described_class.rewrite(document)

      expect(rewritten).not_to be(document)
    end
  end

  describe '.rewrite with a block' do
    it 'rewrites link targets via the block' do
      rewritten = described_class.rewrite(document) do |target:, **|
        target.tr('_', '-')
      end

      paragraph = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      link = find_link(paragraph)
      expect(link.target).to eq('foo-bar.adoc')
    end

    it 'rewrites xref targets via the block' do
      rewritten = described_class.rewrite(document) do |target:, kind:, **|
        next target unless kind == :xref

        "renamed-#{target}"
      end

      paragraph = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      xref = find_xref(paragraph)
      expect(xref.target).to eq('renamed-section_two')
    end

    it 'does NOT rewrite link-shaped text inside verbatim source blocks' do
      rewritten = described_class.rewrite(document) do |target:, **|
        target.tr('_', '-')
      end

      source = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(source.content).to include('link:do_not_touch.adoc')
      expect(source.content).to include('xref:also_do_not_touch')
    end

    it 'preserves the original document (immutability)' do
      original_paragraph = document.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      original_link_target = find_link(original_paragraph).target

      described_class.rewrite(document) { |target:, **| target.tr('_', '-') }

      expect(find_link(original_paragraph).target).to eq(original_link_target)
    end
  end

  describe '.rewrite with a callable object' do
    it 'uses the callable when no block is given' do
      rewriter = Class.new do
        def call(target:, **)
          "prefix:#{target}"
        end
      end.new

      rewritten = described_class.rewrite(document, rewriter: rewriter)

      paragraph = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      link = find_link(paragraph)
      expect(link.target).to eq('prefix:foo_bar.adoc')
    end
  end

  describe 'verbatim block coverage' do
    it 'skips literal blocks' do
      literal_adoc = <<~ADOC
        = Doc

        link:visible.adoc[Visible]

        ....
        link:invisible_literal.adoc[Inside Literal]
        ....
      ADOC
      doc = Coradoc.parse(literal_adoc, format: :asciidoc)

      rewritten = described_class.rewrite(doc) { |target:, **| "rewritten-#{target}" }

      literal = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::LiteralBlock) }
      expect(literal.content).to include('link:invisible_literal.adoc')
    end

    it 'skips pass-through blocks' do
      pass_adoc = <<~ADOC
        = Doc

        link:visible.adoc[Visible]

        ++++
        link:invisible_pass.adoc[Inside Pass]
        ++++
      ADOC
      doc = Coradoc.parse(pass_adoc, format: :asciidoc)

      rewritten = described_class.rewrite(doc) { |target:, **| "rewritten-#{target}" }

      pass = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::PassBlock) }
      expect(pass.content).to include('link:invisible_pass.adoc')
    end

    it 'skips listing blocks' do
      # The adoc parser emits SourceBlock for `----`, not ListingBlock.
      # Construct one directly to verify the visitor's VERBATIM_TYPES
      # coverage is closed: any ListingBlock, regardless of how it was
      # built, must be skipped.
      listing = Coradoc::CoreModel::ListingBlock.new(
        content: 'link:invisible_listing.adoc[Inside Listing]'
      )
      doc = Coradoc::CoreModel::DocumentElement.new(children: [listing])

      rewritten = described_class.rewrite(doc) { |target:, **| "rewritten-#{target}" }

      expect(rewritten.children.first.content).to include('link:invisible_listing.adoc')
    end

    it 'skips stem blocks' do
      stem_adoc = <<~ADOC
        = Doc

        link:visible.adoc[Visible]

        [stem,latexmath]
        ++++
        link:invisible_stem.adoc[Inside Stem]
        ++++
      ADOC
      doc = Coradoc.parse(stem_adoc, format: :asciidoc)

      rewritten = described_class.rewrite(doc) { |target:, **| "rewritten-#{target}" }

      stem = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::StemBlock) }
      expect(stem.content).to include('link:invisible_stem.adoc')
    end
  end

  describe 'nested containers' do
    it 'rewrites links nested inside list items' do
      list_adoc = <<~ADOC
        = Doc

        * See link:foo.adoc[Foo]
        * And link:bar.adoc[Bar]
      ADOC
      doc = Coradoc.parse(list_adoc, format: :asciidoc)

      rewritten = described_class.rewrite(doc) { |target:, **| "renamed-#{target}" }

      list = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      targets = flatten_inlines(list).select { |n| n.is_a?(Coradoc::CoreModel::LinkElement) }.map(&:target)
      expect(targets).to contain_exactly('renamed-foo.adoc', 'renamed-bar.adoc')
    end

    it 'rewrites links nested inside table cells' do
      table_adoc = <<~ADOC
        = Doc

        |===
        | See link:cell_a.adoc[A] | And link:cell_b.adoc[B]
        |===
      ADOC
      doc = Coradoc.parse(table_adoc, format: :asciidoc)

      rewritten = described_class.rewrite(doc) { |target:, **| "tc-#{target}" }

      table = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::Table) }
      targets = flatten_inlines(table).select { |n| n.is_a?(Coradoc::CoreModel::LinkElement) }.map(&:target)
      expect(targets).to contain_exactly('tc-cell_a.adoc', 'tc-cell_b.adoc')
    end
  end

  describe 'Coradoc.rewrite_links facade' do
    it 'exposes the API at the top level' do
      rewritten = Coradoc.rewrite_links(document) { |target:, **| target.tr('_', '-') }

      paragraph = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      link = find_link(paragraph)
      expect(link.target).to eq('foo-bar.adoc')
    end
  end

  describe 'polymorphic link classification (OCP for new inline types)' do
    # The visitor delegates classification to InlineElement#link_kind
    # rather than a class-keyed case/when. Adding a new link-bearing
    # subclass means overriding +link_kind+ on it, not editing the
    # visitor. These specs lock that contract in place.

    it 'classifies LinkElement as :link' do
      node = Coradoc::CoreModel::LinkElement.new(target: 'foo.adoc')
      expect(node.link_kind).to eq(:link)
    end

    it 'classifies CrossReferenceElement as :xref' do
      node = Coradoc::CoreModel::CrossReferenceElement.new(target: 'sec')
      expect(node.link_kind).to eq(:xref)
    end

    it 'classifies generic InlineElement by its format_type' do
      as_link = Coradoc::CoreModel::InlineElement.new(format_type: 'link', target: 'l.adoc')
      as_xref = Coradoc::CoreModel::InlineElement.new(format_type: 'xref', target: 'sec')
      expect(as_link.link_kind).to eq(:link)
      expect(as_xref.link_kind).to eq(:xref)
    end

    it 'returns nil for non-link inlines' do
      bold = Coradoc::CoreModel::BoldElement.new
      expect(bold.link_kind).to be_nil
    end
  end

  def find_link(paragraph)
    return nil unless paragraph

    flatten_inlines(paragraph).find { |n| n.is_a?(Coradoc::CoreModel::LinkElement) }
  end

  def find_xref(paragraph)
    return nil unless paragraph

    flatten_inlines(paragraph).find { |n| n.is_a?(Coradoc::CoreModel::CrossReferenceElement) }
  end

  # Walks a CoreModel subtree collecting every node in pre-order. The
  # CONTAINER_TYPES table is shared with LinkRewriter::Visitor so the
  # spec helper recurses through the same paths the visitor does —
  # no drift when a container type is added (DRY).
  def flatten_inlines(node, acc = [])
    acc << node if node.is_a?(Coradoc::CoreModel::Base)
    each_child(node) { |child| flatten_inlines(child, acc) }
    acc
  end

  def each_child(node, &blk)
    return unless node.is_a?(Coradoc::CoreModel::Base)

    nested = node.nested_elements if node.is_a?(Coradoc::CoreModel::InlineElement)
    Array(nested).each(&blk)

    reader = container_reader_for(node)
    Array(node.public_send(reader)).each(&blk) if reader
  end

  # Mirrors Visitor#reader_for exactly — first is_a? match wins. This
  # catches subclasses (ParagraphBlock < Block, etc.) via the same
  # dispatch the visitor uses.
  def container_reader_for(node)
    CONTAINER_TYPES.each do |klass, reader|
      return reader if node.is_a?(klass)
    end
    nil
  end
end
