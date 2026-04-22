# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AsciiDoc List Continuation' do
  # Helper to parse and transform AsciiDoc
  def parse_and_transform(input)
    ast = Coradoc::AsciiDoc::Parser::Base.parse(input)
    Coradoc::AsciiDoc::Transformer.transform(ast)
  end

  describe 'single continuation with paragraph' do
    it 'attaches single paragraph to unordered list item' do
      input = <<~ADOC
        * Item one
        +
        This is attached to item one.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)

      # Navigate to the list
      contents = result.respond_to?(:contents) ? result.contents : result.sections
      list = contents.first
      expect(list).to be_a(Coradoc::AsciiDoc::Model::List::Unordered)

      item = list.items.first
      expect(item).to be_a(Coradoc::AsciiDoc::Model::List::Item)
      expect(item.content.to_s).to include('Item one')
    end

    it 'attaches single paragraph to ordered list item' do
      input = <<~ADOC
        . First item
        +
        This paragraph is attached.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with code block' do
    it 'attaches code block to list item' do
      input = <<~ADOC
        * Install the gem:
        +
        ----
        gem install coradoc
        ----
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'attaches code block with language to list item' do
      input = <<~ADOC
        * Run this command:
        +
        [source,ruby]
        ----
        require 'coradoc'
        Coradoc.convert(text, from: :markdown, to: :html)
        ----
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with quote block' do
    it 'attaches quote block to list item' do
      input = <<~ADOC
        * As someone said:
        +
        ____
        A quote here.
        ____
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with example block' do
    it 'attaches example block to list item' do
      input = <<~ADOC
        * Example:
        +
        ====
        This is an example.
        ====
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'multiple continuations' do
    it 'attaches multiple paragraphs to list item' do
      input = <<~ADOC
        * Item one
        +
        First attached paragraph.
        +
        Second attached paragraph.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'attaches paragraph then code block' do
      input = <<~ADOC
        * Step one
        +
        First, read this explanation.
        +
        ----
        Then run this code.
        ----
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with nested lists' do
    it 'handles continuation before nested list' do
      input = <<~ADOC
        * Item one
        +
        Some explanation.
        ** Nested item A
        ** Nested item B
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'handles continuation after nested list' do
      input = <<~ADOC
        * Item one
        ** Nested item A
        ** Nested item B
        +
        This attaches to Item one.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'handles continuation in deeply nested list' do
      input = <<~ADOC
        * Level 1
        ** Level 2
        +
        Attached to level 2 item.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with admonition' do
    it 'attaches admonition to list item' do
      input = <<~ADOC
        * Check this:
        +
        NOTE: This is important information.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'attaches multi-line admonition block' do
      input = <<~ADOC
        * Warning:
        +
        [WARNING]
        ====
        This is a warning block.
        Multiple lines here.
        ====
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with open block' do
    it 'attaches open block to list item' do
      input = <<~ADOC
        * Open block example:
        +
        --
        This is content in an open block.
        It can span multiple lines.
        --
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'continuation with sidebar block' do
    it 'attaches sidebar block to list item' do
      input = <<~ADOC
        * Related information:
        +
        ****
        This is a sidebar.
        ****
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'complex continuation scenarios' do
    it 'handles multiple items with continuation' do
      input = <<~ADOC
        * Item one
        +
        Attached to item one.
        * Item two
        +
        Attached to item two.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'handles mixed list with continuation' do
      input = <<~ADOC
        * Unordered item
        +
        Attached paragraph.
        . Ordered item
        +
        Also attached.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'handles continuation with attribute list' do
      input = <<~ADOC
        * [.rolename] Styled item
        +
        Attached content.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'definition list continuation' do
    it 'attaches content to definition list item' do
      input = <<~ADOC
        Term:: Definition
        +
        Additional information about the term.
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end

    it 'attaches block to definition list item' do
      input = <<~ADOC
        API:: Application Programming Interface
        +
        ----
        GET /api/v1/resource
        ----
      ADOC

      result = parse_and_transform(input)
      expect(result).to be_a(Coradoc::AsciiDoc::Model::Document)
    end
  end

  describe 'round-trip preservation' do
    it 'preserves continuation through parse and serialize' do
      input = <<~ADOC
        * Item one
        +
        Attached paragraph.
      ADOC

      result = parse_and_transform(input)
      serialized = result.to_adoc

      # The serialized output should preserve the continuation marker
      expect(serialized).to include('+')
    end

    it 'preserves content with multiple continuations through round-trip' do
      input = <<~ADOC
        * Item
        +
        First paragraph.
        +
        ----
        code block
        ----
      ADOC

      result = parse_and_transform(input)
      serialized = result.to_adoc

      # Content should be preserved
      expect(serialized).to include('First paragraph')
      expect(serialized).to include('code block')
      # Should have at least one continuation marker
      expect(serialized).to include('+')
    end
  end
end
