# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/asciidoc'

# Block-style preservation for `[abstract]`, `[partintro]`, and the generic
# `[admonition]` style. Before this fix, all three collapsed to ExampleBlock
# (mirror type `example`), losing their semantic identity. Each now has a
# dedicated CoreModel class + Mirror node type so the AsciiDoc author's
# intent survives the round-trip.
RSpec.describe 'Named block style preservation', :asciidoc do
  def first_child(adoc)
    Coradoc.parse(adoc, format: :asciidoc).children.first
  end

  describe '[abstract] block style' do
    it 'casts a delimited block into an AbstractBlock', :aggregate_failures do
      block = first_child("[abstract]\n====\nAbstract text\n====\n")

      expect(block).to be_a(Coradoc::CoreModel::AbstractBlock)
      expect(block.content).to eq('Abstract text')
    end

    it 'casts an open block into an AbstractBlock' do
      block = first_child("[abstract]\n--\nAbstract text\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::AbstractBlock)
    end

    it 'reports :abstract as its semantic type', :aggregate_failures do
      block = first_child("[abstract]\n====\nx\n====\n")

      expect(block.class.semantic_type).to eq(:abstract)
      expect(block.resolve_semantic_type).to eq(:abstract)
    end

    it 'preserves block title' do
      block = first_child(".Abstract Title\n[abstract]\n====\nBody\n====\n")

      expect(block.title).to eq('Abstract Title')
    end
  end

  describe '[partintro] block style' do
    it 'casts a delimited block into a PartintroBlock', :aggregate_failures do
      block = first_child("[partintro]\n====\nPart intro\n====\n")

      expect(block).to be_a(Coradoc::CoreModel::PartintroBlock)
      expect(block.content).to eq('Part intro')
    end

    it 'casts an open block into a PartintroBlock' do
      block = first_child("[partintro]\n--\nPart intro\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::PartintroBlock)
    end

    it 'reports :partintro as its semantic type', :aggregate_failures do
      block = first_child("[partintro]\n====\nx\n====\n")

      expect(block.class.semantic_type).to eq(:partintro)
      expect(block.resolve_semantic_type).to eq(:partintro)
    end
  end

  describe 'generic [admonition] block style' do
    it 'casts a delimited block into an AnnotationBlock' do
      block = first_child("[admonition]\n====\nGeneric\n====\n")

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
    end

    it 'canonicalises the type to ADMONITION (uppercase)' do
      block = first_child("[admonition]\n====\nGeneric\n====\n")

      expect(block.annotation_type).to eq('ADMONITION')
    end

    it 'takes precedence over the native ExampleBlock type', :aggregate_failures do
      # The cast ladder resolves admonition before typed-cast, so
      # `[admonition]` on an `====` block is an admonition, not an example.
      block = first_child("[admonition]\n====\nx\n====\n")

      expect(block).not_to be_a(Coradoc::CoreModel::ExampleBlock)
      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
    end

    it 'works on open blocks too', :aggregate_failures do
      block = first_child("[admonition]\n--\nx\n--\n")

      expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(block.annotation_type).to eq('ADMONITION')
    end
  end

  describe 'cast ladder still recognises existing admonitions' do
    %w[note tip warning caution important].each do |style|
      it "[#{style.upcase}] still maps to AnnotationBlock with #{style.upcase} type", :aggregate_failures do
        block = first_child("[#{style.upcase}]\n====\nx\n====\n")

        expect(block).to be_a(Coradoc::CoreModel::AnnotationBlock)
        expect(block.annotation_type).to eq(style.upcase)
      end
    end
  end

  describe 'typed-cast ladder still recognises sidebar/example/quote' do
    it '[sidebar] still maps to SidebarBlock' do
      expect(first_child("[sidebar]\n====\nx\n====\n"))
        .to be_a(Coradoc::CoreModel::SidebarBlock)
    end

    it '[example] still maps to ExampleBlock' do
      expect(first_child("[example]\n====\nx\n====\n"))
        .to be_a(Coradoc::CoreModel::ExampleBlock)
    end

    it '[quote] still maps to QuoteBlock' do
      expect(first_child("[quote]\n====\nx\n====\n"))
        .to be_a(Coradoc::CoreModel::QuoteBlock)
    end
  end
end
