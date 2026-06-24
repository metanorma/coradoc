# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Helpers for JS-shape round-trip specs. Kept in a module so they're
# namespaced and reusable, not loose methods on the example group.
module JSShapeRoundTripHelpers
  module_function

  def round_trip(doc, reverse:)
    mirror = Coradoc::Mirror.transform(doc, partition_structural: true)
    parsed = JSON.parse(JSON.generate(mirror.to_hash))
    rebuilt = Coradoc::Mirror.from_hash(parsed)
    [parsed, reverse.call(rebuilt)]
  end

  def find_first(parsed, type)
    return parsed if parsed.is_a?(Hash) && parsed['type'] == type
    return nil unless parsed.is_a?(Hash) && parsed['content'].is_a?(Array)

    parsed['content'].each do |c|
      found = find_first(c, type)
      return found if found
    end
    nil
  end

  def flatten_children(core)
    core.children.flat_map do |child|
      [child].concat(nested_children_of(child))
    end
  end

  def nested_children_of(child)
    case child
    when Coradoc::CoreModel::DocumentElement,
         Coradoc::CoreModel::SectionElement,
         Coradoc::CoreModel::PreambleElement,
         Coradoc::CoreModel::Block
      flatten_children(child)
    else
      []
    end
  end
end

# Full forward → reverse round-trip coverage of the JS-shape pipeline
# (partition_structural: true). Each example builds a small CoreModel
# document, emits mirror JSON, and verifies:
#   1. The serialized shape matches the @metanorma/mirror JS contract.
#   2. Deserializing back yields semantically equivalent CoreModel.
#
# If a CoreModel field is lost in the round-trip, the spec names it
# explicitly so the gap is auditable (not silently hidden).
RSpec.describe 'JS-shape round-trip' do
  include JSShapeRoundTripHelpers

  let(:reverse) { Coradoc::Mirror::MirrorToCoreModel.new }

  describe 'document with preface, sections, and bibliography' do
    let(:doc) do
      Coradoc::CoreModel::DocumentElement.new(
        title: 'R', id: 'root',
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'intro'),
          Coradoc::CoreModel::SectionElement.new(
            title: 'S1', level: 1, id: 's1', children: [
              Coradoc::CoreModel::ParagraphBlock.new(content: 'body1')
            ]
          ),
          Coradoc::CoreModel::SectionElement.new(
            title: 'S2', level: 1, id: 's2', children: [
              Coradoc::CoreModel::ParagraphBlock.new(content: 'body2')
            ]
          )
        ]
      )
    end

    it 'partitions into [preface, sections] in JSON' do
      parsed, _core = round_trip(doc, reverse: reverse)
      types = parsed['content'].map { |c| c['type'] }
      expect(types).to eq(%w[preface sections])

      preface = parsed['content'][0]['content'].map { |c| c['type'] }
      expect(preface).to eq(%w[paragraph])

      sections = parsed['content'][1]['content']
      expect(sections.map { |s| s['type'] }).to eq(%w[clause clause])
    end

    it 'preserves the title and section structure' do
      _parsed, core = round_trip(doc, reverse: reverse)
      expect(core.title).to eq('R')
      sections = core.children.select { |c| c.is_a?(Coradoc::CoreModel::SectionElement) }
      expect(sections.length).to eq(2)
      expect(sections.map(&:title)).to eq(%w[S1 S2])
    end
  end

  describe 'section with style attribute' do
    it '[appendix] round-trips as annex-typed clause' do
      metadata = Coradoc::CoreModel::Metadata.new
      metadata['style'] = 'appendix'
      doc = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::SectionElement.new(
            title: 'Appendix A', level: 1, attributes: metadata, children: []
          )
        ]
      )

      parsed, _core = round_trip(doc, reverse: reverse)
      sections = parsed['content'].find { |c| c['type'] == 'sections' }
      expect(sections['content'].first['type']).to eq('annex')
    end
  end

  describe 'admonition (NOTE)' do
    let(:doc) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: 'note', content: 'heads up'
          )
        ]
      )
    end

    it 'serializes as admonition with attrs.type' do
      parsed, _core = round_trip(doc, reverse: reverse)
      ad = find_first(parsed, 'admonition')
      expect(ad['attrs']['type']).to eq('note')
      expect(ad['attrs']).not_to include('admonition_type')
    end

    it 'deserializes back to AnnotationBlock with annotation_type=note' do
      _parsed, core = round_trip(doc, reverse: reverse)
      result = flatten_children(core).find { |c| c.is_a?(Coradoc::CoreModel::AnnotationBlock) }
      expect(result).not_to be_nil
      expect(result.annotation_type).to eq('note')
    end
  end

  describe 'image with title' do
    let(:doc) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::Image.new(src: 'a.png', title: 'Fig 1')
        ]
      )
    end

    it 'wraps image in figure with caption child' do
      parsed, _core = round_trip(doc, reverse: reverse)
      figure = find_first(parsed, 'figure')
      expect(figure['content'].map { |c| c['type'] }).to eq(%w[image caption])
    end

    it 'round-trips to Image with caption restored' do
      _parsed, core = round_trip(doc, reverse: reverse)
      result = flatten_children(core).find { |c| c.is_a?(Coradoc::CoreModel::Image) }
      expect(result).not_to be_nil
      expect(result.src).to eq('a.png')
      expect(result.caption).to eq('Fig 1')
    end
  end

  describe 'image without title' do
    it 'stays as a bare image node (no figure wrapping)' do
      doc = Coradoc::CoreModel::DocumentElement.new(
        children: [Coradoc::CoreModel::Image.new(src: 'a.png')]
      )
      parsed, _core = round_trip(doc, reverse: reverse)
      expect(find_first(parsed, 'figure')).to be_nil
      expect(find_first(parsed, 'image')).not_to be_nil
    end
  end

  describe 'sourcecode block' do
    let(:doc) do
      Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::SourceBlock.new(content: "puts 'x'", language: 'ruby')
        ]
      )
    end

    it 'serializes with attrs.text and no content children' do
      parsed, _core = round_trip(doc, reverse: reverse)
      src = find_first(parsed, 'sourcecode')
      expect(src['attrs']['text']).to eq("puts 'x'")
      expect(src['attrs']['language']).to eq('ruby')
      expect(src['content']).to be_nil
    end

    it 'round-trips to SourceBlock with content restored' do
      _parsed, core = round_trip(doc, reverse: reverse)
      result = flatten_children(core).find { |c| c.is_a?(Coradoc::CoreModel::SourceBlock) }
      expect(result).not_to be_nil
      expect(result.content).to eq("puts 'x'")
      expect(result.language).to eq('ruby')
    end
  end
end
