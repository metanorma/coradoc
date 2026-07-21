# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Regression spec for the unified `list_item_attached` rule.
#
# Asciidoctor treats a `+` line directly before any block as a
# continuation of the enclosing list item: the block becomes a child
# of the li or dd rather than a sibling. Before this refactor, the
# `+`-attachment alternation was copy-pasted across `ulist_item`,
# `olist_item`, and `dlist_item`, and only the dlist version accepted
# unordered/ordered lists. The shared `list_item_attached` rule now
# serves all three item types from a single source of truth, and all
# three accept the same attached-block set.
#
# Note: asciidoctor requires the `+` to be on the line immediately
# following the item — a blank line between the item and `+` ends the
# item instead of continuing it. All fixtures below follow that rule.
RSpec.describe '`+`-continuation attachment inside list items', :asciidoc do
  def first_item(adoc)
    parsed = Coradoc.parse(adoc, format: :asciidoc)
    list = parsed.children.first
    list.items.first
  end

  # ListItem stores attached blocks in its generic `children` collection
  # (alongside inline content); DefinitionItem has a dedicated
  # `attached_children` accessor. This helper normalises the two so the
  # shared examples can assert on either.
  def attached_blocks(item)
    if item.is_a?(Coradoc::CoreModel::DefinitionItem)
      item.attached_children
    else
      item.children.reject { |c| c.is_a?(Coradoc::CoreModel::TextContent) }
    end
  end

  shared_examples 'attaches the block via `+`' do
    it 'keeps the parent list with one item' do
      parsed = Coradoc.parse(adoc, format: :asciidoc)
      expect(parsed.children.size).to eq(1)
      list = parsed.children.first
      expect(list.items.size).to eq(1)
    end

    it 'attaches the block as a child of the first item' do
      item = first_item(adoc)
      expect(attached_blocks(item).size).to eq(1)
    end
  end

  context 'inside an unordered list item' do
    let(:adoc) do
      <<~ADOC
        * parent
        +
        Attached paragraph continues the parent item.
      ADOC
    end

    include_examples 'attaches the block via `+`'

    it 'attaches a NOTE admonition via +' do
      adoc = <<~ADOC
        * parent
        +
        NOTE: An admonition attached to the bullet.
      ADOC
      item = first_item(adoc)
      expect(attached_blocks(item).size).to eq(1)
      expect(attached_blocks(item).first).to be_a(Coradoc::CoreModel::AnnotationBlock)
    end

    it 'attaches an unordered list via +' do
      adoc = <<~ADOC
        * parent
        +
        * nested-via-attachment
        * second nested
      ADOC
      item = first_item(adoc)
      expect(attached_blocks(item).size).to eq(1)
      expect(attached_blocks(item).first).to be_a(Coradoc::CoreModel::ListBlock)
    end
  end

  context 'inside an ordered list item' do
    let(:adoc) do
      <<~ADOC
        . parent
        +
        Attached paragraph continues the parent item.
      ADOC
    end

    include_examples 'attaches the block via `+`'

    it 'attaches an unordered list via +' do
      adoc = <<~ADOC
        . parent
        +
        * nested-via-attachment
        * second nested
      ADOC
      item = first_item(adoc)
      expect(attached_blocks(item).size).to eq(1)
      expect(attached_blocks(item).first).to be_a(Coradoc::CoreModel::ListBlock)
    end
  end

  context 'inside a definition list item' do
    let(:adoc) do
      <<~ADOC
        term:: definition
        +
        Attached paragraph continues the dd.
      ADOC
    end

    include_examples 'attaches the block via `+`'

    it 'attaches an unordered list via +' do
      adoc = <<~ADOC
        term:: definition
        +
        * nested-via-attachment
        * second nested
      ADOC
      item = first_item(adoc)
      expect(attached_blocks(item).size).to eq(1)
      expect(attached_blocks(item).first).to be_a(Coradoc::CoreModel::ListBlock)
    end
  end
end
