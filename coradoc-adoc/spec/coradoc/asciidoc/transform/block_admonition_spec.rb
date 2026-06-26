# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

RSpec.describe 'Block-form admonitions', :asciidoc do
  def first_child(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  %w[note tip warning caution important].each do |type|
    context "with [#{type.upcase}] on an example block (====)" do
      it "produces AnnotationBlock with annotation_type '#{type}'" do
        adoc = "[#{type.upcase}]\n====\nbody text\n====\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type)
      end
    end

    context "with [#{type.upcase}] on a sidebar block (****)" do
      it "produces AnnotationBlock with annotation_type '#{type}'" do
        adoc = "[#{type.upcase}]\n****\nbody text\n****\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type)
      end
    end

    context "with [#{type.upcase}] on a quote block (____)" do
      it "produces AnnotationBlock with annotation_type '#{type}'" do
        adoc = "[#{type.upcase}]\n____\nbody text\n____\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type)
      end
    end

    context "with [#{type.upcase}] on an open block (--)" do
      it "produces AnnotationBlock with annotation_type '#{type}'" do
        adoc = "[#{type.upcase}]\n--\nbody text\n--\n"
        block = first_child(adoc)
        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(type)
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
      expect(block.annotation_type).to eq('danger')
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
end
