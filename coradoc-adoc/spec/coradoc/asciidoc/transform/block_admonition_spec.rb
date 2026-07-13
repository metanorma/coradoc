# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

RSpec.describe 'Block-form admonitions', :asciidoc do
  def first_child(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  %w[note tip warning caution important].each do |type|
    context "with [#{type.upcase}] on an example block (====)" do
      it "produces AnnotationBlock with annotation_type '#{type.upcase}'" do
        adoc = "[#{type.upcase}]\n====\nbody text\n====\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type.upcase)
      end
    end

    context "with [#{type.upcase}] on a sidebar block (****)" do
      it "produces AnnotationBlock with annotation_type '#{type.upcase}'" do
        adoc = "[#{type.upcase}]\n****\nbody text\n****\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type.upcase)
      end
    end

    context "with [#{type.upcase}] on a quote block (____)" do
      it "produces AnnotationBlock with annotation_type '#{type.upcase}'" do
        adoc = "[#{type.upcase}]\n____\nbody text\n____\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type.upcase)
      end
    end

    context "with [#{type.upcase}] on an open block (--)" do
      it "produces AnnotationBlock with annotation_type '#{type.upcase}'" do
        adoc = "[#{type.upcase}]\n--\nbody text\n--\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type.upcase)
      end
    end
  end

  context 'without admonition style' do
    it 'still produces ExampleBlock for ==== without [NOTE]' do
      block = first_child("====\nplain\n====\n")
      expect(block).to be_a(Coradoc::CoreModel::ExampleBlock)
    end

    it 'still produces SidebarBlock for **** without [NOTE]' do
      block = first_child("****\nplain\n****\n")
      expect(block).to be_a(Coradoc::CoreModel::SidebarBlock)
    end

    it 'still produces QuoteBlock for ____ without [NOTE]' do
      block = first_child("____\nplain\n____\n")
      expect(block).to be_a(Coradoc::CoreModel::QuoteBlock)
    end
  end

  context 'with custom registered admonition style' do
    after do
      Coradoc::AsciiDoc::Transform::ElementTransformers::AdmonitionStyles.reset!
    end

    it 'recognizes custom-registered styles' do
      styles = Coradoc::AsciiDoc::Transform::ElementTransformers::AdmonitionStyles
      styles.register('danger')
      block = first_child("[DANGER]\n====\nwatch out\n====\n")
      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.annotation_type).to eq('DANGER')
    end
  end

  context 'with verbatim source blocks' do
    it 'does NOT treat [NOTE] on a source block as admonition' do
      # Source semantics win: NOTE on a source block is just an attribute
      # on a listing, not an admonition. (Same as today's behavior.)
      block = first_child("[NOTE]\n----\nputs 'hi'\n----\n")
      expect(block).to be_a(Coradoc::CoreModel::SourceBlock)
    end
  end

  context 'with inline formatting inside delimited admonitions' do
    it 'preserves links, monospace, and bold inside a [NOTE] block' do
      adoc = <<~ADOC
        [NOTE]
        ====
        See link:foo.html[Simple Adoption] with `monospace` and *bold* text.
        ====
      ADOC
      block = first_child(adoc)

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.children.size).to eq(1)
      paragraph = block.children.first
      expect(paragraph).to be_a(Coradoc::CoreModel::ParagraphBlock)

      link = paragraph.children.find { |c| c.is_a?(Coradoc::CoreModel::LinkElement) }
      expect(link).not_to be_nil
      expect(link.target).to eq('foo.html')
      expect(link.content).to eq('Simple Adoption')

      expect(paragraph.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
      expect(paragraph.children.any?(Coradoc::CoreModel::BoldElement)).to be(true)
    end

    it 'preserves the link target from the bug-report reproduction' do
      adoc = <<~ADOC
        [NOTE]
        ====
        Reviewer notes are only rendered
        if link:/author/ref/document-attributes/#draft[:draft:] attribute is set.
        ====
      ADOC
      block = first_child(adoc)
      paragraph = block.children.first

      link = paragraph.children.find { |c| c.is_a?(Coradoc::CoreModel::LinkElement) }
      expect(link).not_to be_nil
      expect(link.target).to eq('/author/ref/document-attributes/#draft')
    end

    it 'preserves paragraph + list structure as separate children' do
      adoc = <<~ADOC
        [NOTE]
        ====
        The easiest way is via link:foo.html[Simple Adoption].

        * Item one with `monospace` text
        * Item two
        ====
      ADOC
      block = first_child(adoc)

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.children.size).to eq(2)
      expect(block.children[0]).to be_a(Coradoc::CoreModel::ParagraphBlock)
      expect(block.children[1]).to be_a(Coradoc::CoreModel::ListBlock)

      paragraph = block.children[0]
      link = paragraph.children.find { |c| c.is_a?(Coradoc::CoreModel::LinkElement) }
      expect(link&.target).to eq('foo.html')

      list = block.children[1]
      expect(list.items.size).to eq(2)
      first_item = list.items.first
      expect(first_item.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end

    it 'preserves multiple blank-line-separated paragraphs' do
      adoc = <<~ADOC
        [WARNING]
        ====
        First paragraph.

        Second paragraph with *bold* text.
        ====
      ADOC
      block = first_child(adoc)

      expect(block.children.size).to eq(2)
      expect(block.children).to all(be_a(Coradoc::CoreModel::ParagraphBlock))
      expect(block.children[0].content).to eq('First paragraph.')
      expect(block.children[1].children.any?(Coradoc::CoreModel::BoldElement)).to be(true)
    end

    it 'preserves inline formatting across every delimited-block form' do
      %w[==== **** ____].each do |delim|
        adoc = "[NOTE]\n#{delim}\nlink:foo.html[bar] and `baz`.\n#{delim}\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock),
                         "expected AnnotationBlock for delimiter #{delim}"
        paragraph = block.children.first
        expect(paragraph).to be_a(Coradoc::CoreModel::ParagraphBlock)
        expect(paragraph.children.any?(Coradoc::CoreModel::LinkElement)).to be(true)
        expect(paragraph.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
      end
    end

    it 'preserves inline formatting on the open-block (-- delimiter) cast' do
      adoc = "[NOTE]\n--\nlink:foo.html[bar] and `baz`.\n--\n"
      block = first_child(adoc)
      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      paragraph = block.children.first
      expect(paragraph.children.any?(Coradoc::CoreModel::LinkElement)).to be(true)
      expect(paragraph.children.any?(Coradoc::CoreModel::MonospaceElement)).to be(true)
    end
  end
end
