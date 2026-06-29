# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# AsciiDoc bullet lists must close at paragraph boundaries. When a
# `*`-marked list is followed (after a blank line) by a regular
# paragraph, the paragraph is a sibling of the list — not a continuation
# of the last list item's text.
#
# Before this fix, `ulist_item` / `olist_item` used `text_line(true, ...)`
# whose `line_ending.repeat(1)` greedy-matched across blank lines,
# silently absorbing the follow-up paragraph into the last item. The
# same bug class also affected ordered lists.
#
# Coverage below locks in:
#   * The bug case (blank-line-separated bullets + paragraph).
#   * Tight lists (no blank lines between items) still produce one list.
#   * Intra-item continuation lines (no blank line) still merge.
#   * Attached blocks via `+` still work.
#   * Ordered lists terminate correctly at paragraph boundaries.
RSpec.describe 'Bullet/ordered list termination at paragraph boundary', :asciidoc do
  def parse(adoc)
    Coradoc.parse(adoc, format: :asciidoc)
  end

  def first_list(adoc)
    parse(adoc).children.find { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
  end

  def top_level_classes(adoc)
    parse(adoc).children.map(&:class)
  end

  describe 'reported bug: blank-line-separated bullets + follow-up paragraph' do
    let(:adoc) do
      <<~ASCIIDOC
        Lead-in paragraph.

        * a unified document model,
        * a serialization format, and
        * a toolchain for authors.

        This year's IBA judges lauded the development.
      ASCIIDOC
    end
    let(:list) { first_list(adoc) }

    it 'produces exactly three list items' do
      expect(list.items.length).to eq(3)
    end

    it 'does not absorb the follow-up paragraph into the last item' do
      last_item = list.items.last
      expect(last_item.content).not_to include("This year's IBA")
    end

    it 'emits the follow-up paragraph as a sibling' do
      paragraph = parse(adoc).children.find do |c|
        c.is_a?(Coradoc::CoreModel::ParagraphBlock) &&
          c.content.to_s.include?("This year's IBA")
      end
      expect(paragraph).to be_a(Coradoc::CoreModel::ParagraphBlock)
    end

    it 'top-level shape is [paragraph, list, paragraph]' do
      expect(top_level_classes(adoc)).to eq([
                                              Coradoc::CoreModel::ParagraphBlock,
                                              Coradoc::CoreModel::ListBlock,
                                              Coradoc::CoreModel::ParagraphBlock
                                            ])
    end
  end

  describe 'reported bug: bullets separated by blank lines' do
    let(:adoc) do
      <<~ASCIIDOC
        * one

        * two

        * three
      ASCIIDOC
    end
    let(:list) { first_list(adoc) }

    it 'still produces a single ListBlock (not three)' do
      lists = parse(adoc).children.select { |c| c.is_a?(Coradoc::CoreModel::ListBlock) }
      expect(lists.length).to eq(1)
    end

    it 'has all three items in the single list' do
      expect(list.items.length).to eq(3)
    end

    it 'preserves each item text independently' do
      expect(list.items.map(&:content)).to eq(%w[one two three])
    end
  end

  describe 'tight list (no blank lines between items)' do
    let(:adoc) { "* alpha\n* beta\n* gamma\n" }
    let(:list) { first_list(adoc) }

    it 'produces one ListBlock with three items' do
      expect(list.items.length).to eq(3)
    end

    it 'preserves each item text' do
      expect(list.items.map(&:content)).to eq(%w[alpha beta gamma])
    end
  end

  describe 'intra-item continuation lines (no blank line)' do
    let(:adoc) { "* item one\n  continued text\n* item two\n" }
    let(:list) { first_list(adoc) }

    it 'merges the continuation line into the first item' do
      expect(list.items.first.content).to include('continued text')
    end

    it 'still recognises both items' do
      expect(list.items.length).to eq(2)
    end
  end

  describe 'attached block via + continuation' do
    let(:adoc) do
      <<~ASCIIDOC
        * item one
        +
        ----
        code line
        ----
      ASCIIDOC
    end

    it 'still parses as a single list with one item' do
      list = first_list(adoc)
      expect(list.items.length).to eq(1)
    end
  end

  describe 'ordered list termination at paragraph boundary' do
    let(:adoc) do
      <<~ASCIIDOC
        . first
        . second
        . third

        Follow-up paragraph.
      ASCIIDOC
    end
    let(:list) { first_list(adoc) }

    it 'produces three ordered items' do
      expect(list.items.length).to eq(3)
    end

    it 'does not absorb the follow-up paragraph' do
      last = list.items.last
      expect(last.content).not_to include('Follow-up')
    end

    it 'emits the paragraph as a sibling' do
      expect(top_level_classes(adoc)).to include(Coradoc::CoreModel::ParagraphBlock)
    end
  end

  describe 'list followed immediately by section header' do
    let(:adoc) do
      <<~ASCIIDOC
        * one
        * two

        == Section Heading

        body
      ASCIIDOC
    end

    it 'terminates the list before the section' do
      list = first_list(adoc)
      expect(list.items.length).to eq(2)
    end

    it 'emits the section as a sibling after the list' do
      section = parse(adoc).children.find do |c|
        c.is_a?(Coradoc::CoreModel::SectionElement)
      end
      expect(section.title).to eq('Section Heading')
    end
  end

  describe 'nested list (no blank line between parent and child)' do
    let(:adoc) { "* parent\n** child\n* parent two\n" }
    let(:list) { first_list(adoc) }

    it 'recognises both parent items' do
      expect(list.items.length).to eq(2)
    end
  end
end
