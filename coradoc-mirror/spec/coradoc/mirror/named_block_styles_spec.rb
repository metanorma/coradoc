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

  describe 'CoreModel::AbstractBlock → Mirror' do
    it 'emits a Node::Abstract with PM_TYPE "abstract_block"' do
      block = Coradoc::CoreModel::AbstractBlock.new(
        content: 'Abstract body',
        title: 'Abs',
        id: 'abs-1'
      )
      doc = Coradoc::CoreModel::DocumentElement.new(children: [block])

      node = Coradoc::Mirror.transform(doc).content.first
      expect(node).to be_a(Coradoc::Mirror::Node::Abstract)
      expect(node.type).to eq('abstract_block')
      expect(node.attrs.title).to eq('Abs')
      expect(node.attrs.id).to eq('abs-1')
    end

    it 'renders the type attribute on the wire' do
      block = Coradoc::CoreModel::AbstractBlock.new(content: 'x')
      doc = Coradoc::CoreModel::DocumentElement.new(children: [block])

      hash = Coradoc::Mirror.transform(doc).content.first.to_hash
      expect(hash['type']).to eq('abstract_block')
    end
  end

  describe 'CoreModel::PartintroBlock → Mirror' do
    it 'emits a Node::Partintro with PM_TYPE "partintro_block"' do
      block = Coradoc::CoreModel::PartintroBlock.new(
        content: 'Part intro',
        title: 'Part 1',
        id: 'pi-1'
      )
      doc = Coradoc::CoreModel::DocumentElement.new(children: [block])

      node = Coradoc::Mirror.transform(doc).content.first
      expect(node).to be_a(Coradoc::Mirror::Node::Partintro)
      expect(node.type).to eq('partintro_block')
      expect(node.attrs.title).to eq('Part 1')
      expect(node.attrs.id).to eq('pi-1')
    end
  end

  describe 'Handlers::Abstract' do
    it 'returns nil for empty content (no abstract emitted)' do
      block = Coradoc::CoreModel::AbstractBlock.new(content: '', children: [])
      node = Coradoc::Mirror::Handlers::Abstract.call(
        block, context: Coradoc::Mirror::CoreModelToMirror.new
      )
      expect(node).to be_nil
    end
  end

  describe 'Handlers::Partintro' do
    it 'returns nil for empty content (no partintro emitted)' do
      block = Coradoc::CoreModel::PartintroBlock.new(content: '', children: [])
      node = Coradoc::Mirror::Handlers::Partintro.call(
        block, context: Coradoc::Mirror::CoreModelToMirror.new
      )
      expect(node).to be_nil
    end
  end

  describe 'reverse builder: abstract_block → AbstractBlock' do
    it 'round-trips Node::Abstract back to CoreModel::AbstractBlock' do
      mirror = Coradoc::Mirror::Node::Abstract.new(
        attrs: Coradoc::Mirror::Node::Abstract::Attrs.new(
          title: 'Abs', id: 'abs-1'
        ),
        content: [Coradoc::Mirror::Node::Text.new(text: 'body')]
      )
      doc = Coradoc::Mirror::Node::Document.new(content: [mirror])

      core = reverse.call(doc)
      expect(core.children.first).to be_a(Coradoc::CoreModel::AbstractBlock)
      expect(core.children.first.title).to eq('Abs')
      expect(core.children.first.id).to eq('abs-1')
    end
  end

  describe 'reverse builder: partintro_block → PartintroBlock' do
    it 'round-trips Node::Partintro back to CoreModel::PartintroBlock' do
      mirror = Coradoc::Mirror::Node::Partintro.new(
        attrs: Coradoc::Mirror::Node::Partintro::Attrs.new(
          title: 'Part 1', id: 'pi-1'
        ),
        content: [Coradoc::Mirror::Node::Text.new(text: 'intro')]
      )
      doc = Coradoc::Mirror::Node::Document.new(content: [mirror])

      core = reverse.call(doc)
      expect(core.children.first).to be_a(Coradoc::CoreModel::PartintroBlock)
      expect(core.children.first.title).to eq('Part 1')
      expect(core.children.first.id).to eq('pi-1')
    end
  end

  describe 'JSON round-trip (forward → JSON → reverse → CoreModel)' do
    it 'preserves AbstractBlock identity through JSON' do
      original = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::AbstractBlock.new(
            title: 'Abs',
            children: [Coradoc::CoreModel::ParagraphBlock.new(content: 'Body')]
          )
        ]
      )
      json1 = Coradoc.serialize(original, to: :mirror_json)
      parsed = Coradoc::Mirror.from_hash(JSON.parse(json1))
      rebuilt = reverse.call(parsed)

      expect(rebuilt.children.first).to be_a(Coradoc::CoreModel::AbstractBlock)
      expect(rebuilt.children.first.title).to eq('Abs')

      # JSON shape is stable across the round-trip.
      json2 = Coradoc.serialize(rebuilt, to: :mirror_json)
      expect(JSON.parse(json2)).to eq(JSON.parse(json1))
    end

    it 'preserves PartintroBlock identity through JSON' do
      original = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::PartintroBlock.new(
            title: 'Intro',
            children: [Coradoc::CoreModel::ParagraphBlock.new(content: 'Body')]
          )
        ]
      )
      json1 = Coradoc.serialize(original, to: :mirror_json)
      parsed = Coradoc::Mirror.from_hash(JSON.parse(json1))
      rebuilt = reverse.call(parsed)

      expect(rebuilt.children.first).to be_a(Coradoc::CoreModel::PartintroBlock)
      expect(rebuilt.children.first.title).to eq('Intro')

      json2 = Coradoc.serialize(rebuilt, to: :mirror_json)
      expect(JSON.parse(json2)).to eq(JSON.parse(json1))
    end
  end

  describe 'generic [admonition] block style' do
    it 'emits an Admonition node with attrs.type="ADMONITION"' do
      block = Coradoc::CoreModel::AnnotationBlock.new(
        annotation_type: 'ADMONITION',
        content: 'Generic'
      )
      doc = Coradoc::CoreModel::DocumentElement.new(children: [block])

      hash = Coradoc::Mirror.transform(doc).content.first.to_hash
      expect(hash['type']).to eq('admonition')
      expect(hash['attrs']['type']).to eq('ADMONITION')
    end

    it 'round-trips generic admonition back to AnnotationBlock' do
      original = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: 'ADMONITION',
            content: 'Generic'
          )
        ]
      )
      json1 = Coradoc.serialize(original, to: :mirror_json)
      parsed = Coradoc::Mirror.from_hash(JSON.parse(json1))
      rebuilt = reverse.call(parsed)

      expect(rebuilt.children.first).to be_a(Coradoc::CoreModel::AnnotationBlock)
      expect(rebuilt.children.first.annotation_type).to eq('ADMONITION')
    end
  end
end
