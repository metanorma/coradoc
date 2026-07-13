# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Regression spec for the delimited-block inline-formatting fix.
# Before the fix, every typed block (example, sidebar, quote, open,
# and the admonition cast) flattened inline content to plain text
# whenever a block-level sibling (list, table, nested block) was
# also present: the `has_nested_blocks` branch in transform_typed_block
# ran each line through extract_text_content, stripping all marks.
#
# The unified grouping algorithm in BlockTransformer.build_typed_block_children
# preserves inline formatting by wrapping consecutive inline lines in
# ParagraphBlock children (with their inline marks intact) and slotting
# dispatched block-level children in at their original document-order
# positions.
RSpec.describe 'Typed blocks with mixed inline + block content', :asciidoc do
  def first_child(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  def find_inline_of_class(paragraph, klass)
    paragraph.children.find { |c| c.is_a?(klass) }
  end

  shared_examples 'preserves inline formatting alongside a list' do
    it 'produces ParagraphBlock + ListBlock children with inline marks intact' do
      block = first_child(adoc)

      expect(block).to be_a(block_class)
      expect(block.children.size).to eq(2)
      expect(block.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(block.children[1]).to be_a(Coradoc::CoreModel::ListBlock)

      paragraph = block.children[0]
      link = find_inline_of_class(paragraph, Coradoc::CoreModel::LinkElement)
      expect(link).not_to be_nil
      expect(link.target).to eq('foo.html')
      expect(link.content).to eq('Simple Adoption')

      list = block.children[1]
      expect(list.items.size).to eq(2)
      first_item = list.items.first
      expect(first_item.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end
  end

  context 'inside an example block (====)' do
    let(:block_class) { Coradoc::CoreModel::ExampleBlock }
    let(:adoc) do
      <<~ADOC
        ====
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        ====
      ADOC
    end

    it_behaves_like 'preserves inline formatting alongside a list'
  end

  context 'inside a sidebar block (****)' do
    let(:block_class) { Coradoc::CoreModel::SidebarBlock }
    let(:adoc) do
      <<~ADOC
        ****
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        ****
      ADOC
    end

    it_behaves_like 'preserves inline formatting alongside a list'
  end

  context 'inside a quote block (____)' do
    let(:block_class) { Coradoc::CoreModel::QuoteBlock }
    let(:adoc) do
      <<~ADOC
        ____
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        ____
      ADOC
    end

    it_behaves_like 'preserves inline formatting alongside a list'
  end

  context 'inside an open block (--)' do
    let(:block_class) { Coradoc::CoreModel::OpenBlock }
    let(:adoc) do
      <<~ADOC
        --
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        --
      ADOC
    end

    it_behaves_like 'preserves inline formatting alongside a list'
  end

  context 'inside a typed-cast open block ([example])' do
    let(:block_class) { Coradoc::CoreModel::ExampleBlock }
    let(:adoc) do
      <<~ADOC
        [example]
        --
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        --
      ADOC
    end

    it_behaves_like 'preserves inline formatting alongside a list'
  end

  context 'with paragraph followed immediately by a list (no blank line)' do
    it 'still produces ParagraphBlock then ListBlock' do
      block = first_child(<<~ADOC)
        --
        Lead-in text.
        * a
        * b
        --
      ADOC

      expect(block.children.size).to eq(2)
      expect(block.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(block.children[1]).to be_a(Coradoc::CoreModel::ListBlock)
    end
  end

  context 'with only nested block children (no inline prose)' do
    it 'omits content but preserves dispatched children' do
      nested = first_child(<<~ADOC)
        --
        [example]
        ====
        inner
        ====
        --
      ADOC

      expect(nested).to be_a(Coradoc::CoreModel::OpenBlock)
      expect(nested.content).to be_nil
      expect(nested.children.size).to eq(1)
      expect(nested.children.first).to be_a(Coradoc::CoreModel::ExampleBlock)
    end
  end

  context 'with only inline prose (no nested blocks)' do
    it 'produces a single ParagraphBlock with inline marks' do
      block = first_child(<<~ADOC)
        ====
        See link:foo.html[foo] and `bar`.
        ====
      ADOC

      expect(block).to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(block.children.size).to eq(1)
      paragraph = block.children.first
      expect(paragraph).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(paragraph.children.any?(Coradoc::CoreModel::LinkElement)).to be(true)
      expect(paragraph.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end
  end

  context 'with content attribute derived from paragraph children' do
    it 'joins paragraph texts with blank-line separators' do
      block = first_child(<<~ADOC)
        ====
        First paragraph.

        Second paragraph.
        ====
      ADOC

      expect(block.content).to eq("First paragraph.\n\nSecond paragraph.")
    end

    it 'is nil when the block contains only nested blocks' do
      block = first_child(<<~ADOC)
        --
        [example]
        ====
        inner
        ====
        --
      ADOC

      expect(block.content).to be_nil
    end
  end
end
