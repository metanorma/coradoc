# frozen_string_literal: true

require 'spec_helper'

# FrontmatterQuery is the public read-API for downstream consumers (e.g.
# metanorma.org's convert-adoc.rb) that need a flat Ruby Hash of a Mirror
# doc's frontmatter without re-parsing source YAML. Locks in:
#   1. Round-trip fidelity (CoreModel frontmatter data → mirror → flat Hash)
#   2. Graceful nil/empty handling
#   3. Nested values, arrays, dates — all preserved through the typed tree
RSpec.describe Coradoc::Mirror::FrontmatterQuery do
  describe '.to_hash' do
    it 'returns an empty hash when the doc has no frontmatter node' do
      doc = Coradoc::Mirror::Node::Document.new(
        content: [Coradoc::Mirror::Node::Paragraph.new]
      )
      expect(described_class.to_hash(doc)).to eq({})
    end

    it 'returns an empty hash when the doc is nil' do
      expect(described_class.to_hash(nil)).to eq({})
    end

    it 'returns an empty hash when the frontmatter node has no entries' do
      frontmatter = Coradoc::Mirror::Node::Frontmatter.new(
        attrs: Coradoc::Mirror::Node::Frontmatter::Attrs.new
      )
      doc = Coradoc::Mirror::Node::Document.new(content: [frontmatter])
      expect(described_class.to_hash(doc)).to eq({})
    end

    it 'round-trips a simple title-only frontmatter block through the mirror' do
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'Hello' })
        ]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      expect(described_class.to_hash(mirror)).to eq({ 'title' => 'Hello' })
    end

    it 'preserves nested maps, arrays, integers, booleans, dates' do
      data = {
        'title'    => 'Doc',
        'tags'     => %w[a b c],
        'count'    => 7,
        'draft'    => false,
        'published'=> Date.new(2026, 6, 24),
        'author'   => { 'name' => 'Ada', 'email' => 'ada@example.com' }
      }
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [Coradoc::CoreModel::FrontmatterBlock.new(data: data)]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      result = described_class.to_hash(mirror)
      expect(result).to eq(data)
    end

    it 'finds frontmatter even when wrapped in partitioned structural buckets' do
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'T' }),
          Coradoc::CoreModel::SectionElement.new(title: 'S', level: 1)
        ]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      expect(described_class.to_hash(mirror)).to eq({ 'title' => 'T' })
    end
  end

  describe '.has_frontmatter?' do
    it 'is false for a doc with no frontmatter' do
      doc = Coradoc::Mirror::Node::Document.new(
        content: [Coradoc::Mirror::Node::Paragraph.new]
      )
      expect(described_class.has_frontmatter?(doc)).to be false
    end

    it 'is false for nil' do
      expect(described_class.has_frontmatter?(nil)).to be false
    end

    it 'is true when the frontmatter node has at least one entry' do
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'X' })
        ]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      expect(described_class.has_frontmatter?(mirror)).to be true
    end

    it 'is false when the frontmatter node exists but has no entries' do
      frontmatter = Coradoc::Mirror::Node::Frontmatter.new(
        attrs: Coradoc::Mirror::Node::Frontmatter::Attrs.new
      )
      doc = Coradoc::Mirror::Node::Document.new(content: [frontmatter])
      expect(described_class.has_frontmatter?(doc)).to be false
    end
  end
end
