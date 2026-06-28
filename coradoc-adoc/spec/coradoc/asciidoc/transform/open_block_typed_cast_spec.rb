# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Open blocks (`--`) are generic containers in AsciiDoc. A positional
# style attribute on the open block can cast it into a richer semantic
# type — e.g. `[sidebar]\n--\nSide\n--` is semantically a sidebar,
# not an open block. Single source of truth for the cast ladder lives
# in BlockTransformer::TYPED_BLOCK_CAST_STYLES.
RSpec.describe 'Open-block typed casts', :asciidoc do
  def first_child(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  describe '[sidebar] cast' do
    it 'casts an open block into a SidebarBlock' do
      block = first_child("[sidebar]\n--\nSide content\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::SidebarBlock)
      expect(block.content).to eq('Side content')
    end
  end

  describe '[example] cast' do
    it 'casts an open block into an ExampleBlock' do
      block = first_child("[example]\n--\nExample body\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(block.content).to eq('Example body')
    end
  end

  describe '[quote] cast' do
    it 'casts an open block into a QuoteBlock' do
      block = first_child("[quote]\n--\nQuoted text\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::QuoteBlock)
      expect(block.content).to eq('Quoted text')
    end
  end

  describe 'uncast open block' do
    it 'keeps a plain open block as OpenBlock' do
      block = first_child("--\nJust open\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::OpenBlock)
    end
  end

  describe 'cast precedence (admonition > typed)' do
    it 'prefers admonition when both could apply' do
      # [NOTE] is an admonition label, not a typed-cast style.
      # The cast ladder resolves admonition before typed-cast.
      block = first_child("[NOTE]\n--\nwatch out\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.annotation_type).to eq('NOTE')
    end
  end
end
