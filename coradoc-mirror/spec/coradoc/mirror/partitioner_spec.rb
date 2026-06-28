# frozen_string_literal: true

require 'spec_helper'

# Partitioner is a single-pass state machine that buckets built Mirror
# nodes for the JS-shape doc structure. These specs lock in the bucketing
# rules — including the metadata (frontmatter) bucket — so accidental
# regressions are caught.
RSpec.describe Coradoc::Mirror::Partitioner do
  def para(text = 'x')
    Coradoc::Mirror::Node::Paragraph.new(
      content: [Coradoc::Mirror::Node::Text.new(text: text)]
    )
  end

  def clause(title = 'C')
    Coradoc::Mirror::Node::Section.new(
      type: 'clause',
      attrs: Coradoc::Mirror::Node::Section::Attrs.new(title: title, level: 1)
    )
  end

  def frontmatter_with(entries)
    Coradoc::Mirror::Node::Frontmatter.new(
      attrs: Coradoc::Mirror::Node::Frontmatter::Attrs.new(entries: entries)
    )
  end

  describe '.partition' do
    it 'places frontmatter in the metadata bucket, NOT preface' do
      fm = frontmatter_with([
                              Coradoc::Mirror::Node::FrontmatterEntry.new(
                                key: 'title',
                                value: Coradoc::Mirror::Node::FrontmatterValue.new(
                                  value_type: 'string', string_value: 'Doc'
                                )
                              )
                            ])
      buckets = described_class.partition([fm, para, clause])

      expect(buckets[:metadata]).to eq([fm])
      expect(buckets[:preface]).to eq([para])
      expect(buckets[:sections]).to eq([clause])
    end

    it 'preserves document order when frontmatter is sandwiched' do
      # Documents always emit frontmatter first; the partitioner must not
      # reorder it relative to other metadata-bearing nodes.
      fm = frontmatter_with([])
      buckets = described_class.partition([fm, para, clause])

      expect(buckets[:metadata]).to eq([fm])
      expect(buckets[:preface]).to eq([para])
      expect(buckets[:sections]).to eq([clause])
    end

    it 'always returns the five-bucket shape' do
      buckets = described_class.partition([])
      expect(buckets.keys).to contain_exactly(:preface, :sections, :bibliography,
                                              :trailing, :metadata)
    end

    it 'routes footnotes to trailing regardless of frontmatter presence' do
      fn = Coradoc::Mirror::Node::Footnotes.new
      buckets = described_class.partition([frontmatter_with([]), fn])
      expect(buckets[:trailing]).to eq([fn])
      expect(buckets[:metadata]).to eq([frontmatter_with([])])
    end
  end

  describe 'integration with CoreModelToMirror (partition_structural: true)' do
    it 'emits frontmatter before preface in the wrapped doc' do
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'T' }),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'intro'),
          Coradoc::CoreModel::SectionElement.new(title: 'S', level: 1)
        ]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      types = mirror.content.map(&:type)
      expect(types).to eq(%w[frontmatter preface sections])
    end

    it 'does not include frontmatter inside the preface bucket' do
      core = Coradoc::CoreModel::DocumentElement.new(
        children: [
          Coradoc::CoreModel::FrontmatterBlock.new(data: { 'title' => 'T' }),
          Coradoc::CoreModel::ParagraphBlock.new(content: 'intro')
        ]
      )
      mirror = Coradoc::Mirror.transform(core, partition_structural: true)
      preface = mirror.content.find { |n| n.type == 'preface' }
      expect(preface.content.map(&:type)).to eq(%w[paragraph])
    end
  end
end
