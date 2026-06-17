# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::FrontmatterBlock do
  describe 'class identity' do
    it 'is a Block subclass' do
      expect(described_class.ancestors).to include(Coradoc::CoreModel::Block)
    end

    it 'has semantic_type :frontmatter' do
      expect(described_class.semantic_type).to eq(:frontmatter)
    end

    it 'has element_type_name frontmatter' do
      expect(described_class.element_type_name).to eq('frontmatter')
    end
  end

  describe '#schema' do
    it 'defaults to nil' do
      expect(described_class.new.schema).to be_nil
    end

    it 'accepts a schema URL' do
      block = described_class.new(schema: 'https://example.com/schema.json')
      expect(block.schema).to eq('https://example.com/schema.json')
    end
  end

  describe '#data' do
    it 'defaults to an empty hash' do
      expect(described_class.new.data).to eq({})
    end

    it 'holds arbitrary YAML-derived values keyed by string' do
      block = described_class.new(
        data: {
          'title' => 'Hello',
          'count' => 42,
          'tags' => %w[a b]
        }
      )

      expect(block.data['title']).to eq('Hello')
      expect(block.data['count']).to eq(42)
      expect(block.data['tags']).to eq(%w[a b])
    end
  end

  describe '#entry' do
    it 'returns the value for a matching string key' do
      block = described_class.new(data: { 'title' => 'Hello' })
      expect(block.entry('title')).to eq('Hello')
    end

    it 'accepts symbol keys' do
      block = described_class.new(data: { 'title' => 'Hello' })
      expect(block.entry(:title)).to eq('Hello')
    end

    it 'returns nil for absent key' do
      expect(described_class.new.entry('absent')).to be_nil
    end
  end

  describe '#has_entry?' do
    it 'returns true when the key exists' do
      block = described_class.new(data: { 'x' => 'y' })
      expect(block.has_entry?('x')).to be true
      expect(block.has_entry?(:x)).to be true
    end

    it 'returns false when the key is absent' do
      expect(described_class.new.has_entry?('x')).to be false
    end
  end

  describe '#empty?' do
    it 'returns true for a fresh block' do
      expect(described_class.new).to be_empty
    end

    it 'returns false when schema is set' do
      expect(described_class.new(schema: 'x')).not_to be_empty
    end

    it 'returns false when data is present' do
      block = described_class.new(data: { 'x' => 'y' })
      expect(block).not_to be_empty
    end
  end

  describe 'sub-namespace autoloads' do
    it 'loads Codec' do
      expect(described_class::Codec).to be_a(Module)
    end

    it 'loads SchemaResolver' do
      expect(described_class::SchemaResolver).to be_a(Module)
    end

    it 'loads FieldTransform' do
      expect(described_class::FieldTransform).to be_a(Module)
    end
  end
end
