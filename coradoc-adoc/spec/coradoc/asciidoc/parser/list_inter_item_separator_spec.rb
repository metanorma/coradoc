# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Regression spec for the unified list-item separator rule.
#
# Asciidoctor treats blank lines and `//` comment lines as non-terminating
# inside every list type (unordered, ordered, definition). Before this
# refactor, only the definition list consumed inter-item comments;
# unordered and ordered lists split into siblings when a `//` comment
# appeared between items. The unified `list_item_separator` rule now
# serves all three list types from a single source of truth.
#
# This spec locks in the parallel behavior across all list types so
# future grammar changes keep them in sync.
RSpec.describe 'Inter-item separators inside lists', :asciidoc do
  def top_level_children(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children
  end

  def class_list(children)
    children.map { |c| c.class.name }.join(', ')
  end

  def list_with_two_items(adoc, list_class)
    children = top_level_children(adoc)
    expect(children.size).to eq(1),
                             lambda {
                               "expected one top-level list, got #{class_list(children)}"
                             }
    expect(children.first).to be_a(list_class)
    children.first
  end

  shared_examples 'a list that survives inter-item comments' do
    it 'keeps a single list when a // comment separates items' do
      list = list_with_two_items(adoc_with_comment, list_class)
      expect(list.items.size).to eq(2)
    end

    it 'keeps a single list when multiple // comments separate items' do
      list = list_with_two_items(adoc_with_multiple_comments, list_class)
      expect(list.items.size).to eq(2)
    end

    it 'does not silently swallow tag directives between items' do
      # Tag directives (`// tag::name[]`, `// end::name[]`) are
      # structural region markers, not comments. `comment_line_content`
      # rejects them via `tag.absent?`, so they cannot serve as an
      # inter-item separator — the list splits so the tag retains its
      # own position in the parse tree.
      children = top_level_children(adoc_with_tag_directive)
      expect(children.size).to eq(2),
                               lambda {
                                 "expected the tag directive to split the list, got #{class_list(children)}"
                               }
      expect(children.all?(list_class)).to be(true)
    end

    it 'still ends the list at a paragraph' do
      # A paragraph between items is real content, not a separator.
      # The list must split so the paragraph renders between them.
      children = top_level_children(adoc_with_paragraph_between)
      expect(children.size).to eq(3)
      expect(children[0]).to be_a(list_class)
      expect(children[1]).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(children[2]).to be_a(list_class)
    end
  end

  context 'with an unordered list' do
    let(:list_class) { Coradoc::CoreModel::ListBlock }

    let(:adoc_with_comment) do
      <<~ADOC
        * one

        // a comment between items

        * two
      ADOC
    end

    let(:adoc_with_multiple_comments) do
      <<~ADOC
        * one

        // first comment
        // second comment

        * two
      ADOC
    end

    let(:adoc_with_tag_directive) do
      <<~ADOC
        * one

        // tag::region[]

        * two
      ADOC
    end

    let(:adoc_with_paragraph_between) do
      <<~ADOC
        * one

        A paragraph in the middle.

        * two
      ADOC
    end

    it_behaves_like 'a list that survives inter-item comments'
  end

  context 'with an ordered list' do
    let(:list_class) { Coradoc::CoreModel::ListBlock }

    let(:adoc_with_comment) do
      <<~ADOC
        . one

        // a comment between items

        . two
      ADOC
    end

    let(:adoc_with_multiple_comments) do
      <<~ADOC
        . one

        // first comment
        // second comment

        . two
      ADOC
    end

    let(:adoc_with_tag_directive) do
      <<~ADOC
        . one

        // tag::region[]

        . two
      ADOC
    end

    let(:adoc_with_paragraph_between) do
      <<~ADOC
        . one

        A paragraph in the middle.

        . two
      ADOC
    end

    it_behaves_like 'a list that survives inter-item comments'
  end

  context 'with a definition list' do
    let(:list_class) { Coradoc::CoreModel::DefinitionList }

    let(:adoc_with_comment) do
      <<~ADOC
        one:: first

        // a comment between items

        two:: second
      ADOC
    end

    let(:adoc_with_multiple_comments) do
      <<~ADOC
        one:: first

        // first comment
        // second comment

        two:: second
      ADOC
    end

    let(:adoc_with_tag_directive) do
      <<~ADOC
        one:: first

        // tag::region[]

        two:: second
      ADOC
    end

    let(:adoc_with_paragraph_between) do
      <<~ADOC
        one:: first

        A paragraph in the middle.

        two:: second
      ADOC
    end

    it_behaves_like 'a list that survives inter-item comments'
  end

  context 'with a // comment whose text contains a :: delimiter' do
    # This is the ITU bug from the original bug report: a comment like
    # `// foo :: bar` was parsed as a bogus dlist term `// foo` because
    # the comment-line rule was not consumed before the dlist_item
    # attempt. The unified separator now consumes the comment wholesale
    # before the next dlist_item is tried.
    it 'does not parse the comment as a dlist term' do
      adoc = <<~ADOC
        one:: first

        // bogus :: term

        two:: second
      ADOC

      list = list_with_two_items(adoc, Coradoc::CoreModel::DefinitionList)
      expect(list.items.map(&:term)).to eq(%w[one two])
    end
  end
end
