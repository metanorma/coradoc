# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Mirror-side coverage for the named block styles that previously collapsed
# to `example` (Issue 2 from STATUS-2026-06-28). Each style now has:
#
#   - a dedicated CoreModel class (AbstractBlock / PartintroBlock)
#   - a dedicated Mirror::Node class (Node::Abstract / Node::Partintro)
#   - a Handler that maps CoreModel → Mirror node
#   - a ReverseBuilder that maps Mirror node → CoreModel
#
# The wire names are `abstract_block` and `partintro_block` so they do
# not collide with the Section PM_ALIAS `abstract` (used for section-style
# abstracts). The generic `[admonition]` style reuses the existing
# Admonition node with `attrs.type: "ADMONITION"`.
RSpec.describe 'Named block style mirror coverage', :asciidoc do
  let(:reverse) { Coradoc::Mirror::MirrorToCoreModel.new }
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe 'CoreModel::AbstractBlock → Mirror' do
    let(:block) do
      Coradoc::CoreModel::AbstractBlock.new(
        content: 'Abstract body', title: 'Abs', id: 'abs-1'
      )
    end
    let(:doc) { Coradoc::CoreModel::DocumentElement.new(children: [block]) }
    let(:node) { Coradoc::Mirror.transform(doc).content.first }

    it 'emits a Node::Abstract' do
      expect(node).to be_a(Coradoc::Mirror::Node::Abstract)
    end

    it 'preserves PM_TYPE "abstract_block"' do
      expect(node.type).to eq('abstract_block')
    end

    it 'preserves title and id attrs', :aggregate_failures do
      expect(node.attrs.title).to eq('Abs')
      expect(node.attrs.id).to eq('abs-1')
    end

    it 'renders the type attribute on the wire' do
      expect(node.to_hash['type']).to eq('abstract_block')
    end
  end

  describe 'CoreModel::PartintroBlock → Mirror' do
    let(:block) do
      Coradoc::CoreModel::PartintroBlock.new(
        content: 'Part intro', title: 'Part 1', id: 'pi-1'
      )
    end
    let(:doc) { Coradoc::CoreModel::DocumentElement.new(children: [block]) }
    let(:node) { Coradoc::Mirror.transform(doc).content.first }

    it 'emits a Node::Partintro' do
      expect(node).to be_a(Coradoc::Mirror::Node::Partintro)
    end

    it 'preserves PM_TYPE "partintro_block"' do
      expect(node.type).to eq('partintro_block')
    end

    it 'preserves title and id attrs', :aggregate_failures do
      expect(node.attrs.title).to eq('Part 1')
      expect(node.attrs.id).to eq('pi-1')
    end
  end

  describe 'Handlers::Abstract' do
    it 'returns nil for empty content' do
      block = Coradoc::CoreModel::AbstractBlock.new(content: '', children: [])
      node = Coradoc::Mirror::Handlers::Abstract.call(block, context: context)
      expect(node).to be_nil
    end
  end

  describe 'Handlers::Partintro' do
    it 'returns nil for empty content' do
      block = Coradoc::CoreModel::PartintroBlock.new(content: '', children: [])
      node = Coradoc::Mirror::Handlers::Partintro.call(block, context: context)
      expect(node).to be_nil
    end
  end

  describe 'reverse builder: abstract_block → AbstractBlock' do
    let(:mirror) do
      Coradoc::Mirror::Node::Abstract.new(
        attrs: Coradoc::Mirror::Node::Abstract::Attrs.new(
          title: 'Abs', id: 'abs-1'
        ),
        content: [Coradoc::Mirror::Node::Text.new(text: 'body')]
      )
    end
    let(:doc) { Coradoc::Mirror::Node::Document.new(content: [mirror]) }
    let(:rebuilt) { reverse.call(doc).children.first }

    it 'yields a CoreModel::AbstractBlock' do
      expect(rebuilt).to be_a(Coradoc::CoreModel::AbstractBlock)
    end

    it 'preserves the title' do
      expect(rebuilt.title).to eq('Abs')
    end

    it 'preserves the id' do
      expect(rebuilt.id).to eq('abs-1')
    end
  end

  describe 'reverse builder: partintro_block → PartintroBlock' do
    let(:mirror) do
      Coradoc::Mirror::Node::Partintro.new(
        attrs: Coradoc::Mirror::Node::Partintro::Attrs.new(
          title: 'Part 1', id: 'pi-1'
        ),
        content: [Coradoc::Mirror::Node::Text.new(text: 'intro')]
      )
    end
    let(:doc) { Coradoc::Mirror::Node::Document.new(content: [mirror]) }
    let(:rebuilt) { reverse.call(doc).children.first }

    it 'yields a CoreModel::PartintroBlock' do
      expect(rebuilt).to be_a(Coradoc::CoreModel::PartintroBlock)
    end

    it 'preserves the title' do
      expect(rebuilt.title).to eq('Part 1')
    end

    it 'preserves the id' do
      expect(rebuilt.id).to eq('pi-1')
    end
  end

  describe 'JSON round-trip: AbstractBlock' do
    let(:original) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::AbstractBlock.new(
            title: 'Abs',
            children: [Coradoc::CoreModel::ParagraphBlock.new(content: 'Body')]
          )
        ]
      )
    end
    let(:json1) { Coradoc.serialize(original, to: :mirror_json) }
    let(:rebuilt) { reverse.call(Coradoc::Mirror.from_hash(JSON.parse(json1))) }

    it 'preserves AbstractBlock identity' do
      expect(rebuilt.children.first).to be_a(Coradoc::CoreModel::AbstractBlock)
    end

    it 'preserves the title through JSON' do
      expect(rebuilt.children.first.title).to eq('Abs')
    end

    it 'produces stable JSON across the round-trip' do
      json2 = Coradoc.serialize(rebuilt, to: :mirror_json)
      expect(JSON.parse(json2)).to eq(JSON.parse(json1))
    end
  end

  describe 'JSON round-trip: PartintroBlock' do
    let(:original) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::PartintroBlock.new(
            title: 'Intro',
            children: [Coradoc::CoreModel::ParagraphBlock.new(content: 'Body')]
          )
        ]
      )
    end
    let(:json1) { Coradoc.serialize(original, to: :mirror_json) }
    let(:rebuilt) { reverse.call(Coradoc::Mirror.from_hash(JSON.parse(json1))) }

    it 'preserves PartintroBlock identity' do
      expect(rebuilt.children.first).to be_a(Coradoc::CoreModel::PartintroBlock)
    end

    it 'preserves the title through JSON' do
      expect(rebuilt.children.first.title).to eq('Intro')
    end

    it 'produces stable JSON across the round-trip' do
      json2 = Coradoc.serialize(rebuilt, to: :mirror_json)
      expect(JSON.parse(json2)).to eq(JSON.parse(json1))
    end
  end

  describe 'generic [admonition] block style' do
    let(:block) do
      Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'ADMONITION', content: 'Generic'
      )
    end
    let(:doc) { Coradoc::CoreModel::DocumentElement.new(children: [block]) }
    let(:node) { Coradoc::Mirror.transform(doc).content.first }

    it 'emits an Admonition node' do
      expect(node.type).to eq('admonition')
    end

    it 'carries the ADMONITION type in attrs' do
      expect(node.to_hash['attrs']['type']).to eq('ADMONITION')
    end

    it 'round-trips back to AnnotationBlock', :aggregate_failures do
      json = Coradoc.serialize(doc, to: :mirror_json)
      rebuilt = reverse.call(Coradoc::Mirror.from_hash(JSON.parse(json)))
      result = rebuilt.children.first

      expect(result).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(result.annotation_type).to eq('ADMONITION')
    end
  end
end
