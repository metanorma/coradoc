# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'

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
  end

  describe 'Coradoc.rewrite_links facade' do
    it 'exposes the API at the top level' do
      rewritten = Coradoc.rewrite_links(document) { |target:, **| target.tr('_', '-') }

      paragraph = rewritten.children.find { |c| c.is_a?(Coradoc::CoreModel::ParagraphBlock) }
      link = find_link(paragraph)
      expect(link.target).to eq('foo-bar.adoc')
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

  def flatten_inlines(node, acc = [])
    children = nil
    nested = nil

    case node
    when Coradoc::CoreModel::InlineElement
      nested = node.nested_elements
    when Coradoc::CoreModel::DocumentElement,
         Coradoc::CoreModel::SectionElement,
         Coradoc::CoreModel::ParagraphBlock,
         Coradoc::CoreModel::Block
      children = node.children
    end

    Array(children).each { |child| collect_inline(child, acc) }
    Array(nested).each { |child| collect_inline(child, acc) }
    acc
  end

  def collect_inline(child, acc)
    return unless child.is_a?(Coradoc::CoreModel::Base)

    acc << child
    flatten_inlines(child, acc)
  end
end
