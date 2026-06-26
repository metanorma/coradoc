# frozen_string_literal: true

require 'spec_helper'
require 'date'

RSpec.describe Coradoc::CoreModel::FrontmatterBlock::Codec do
  let(:flat_yaml) do
    <<~YAML.strip
      title: Foo
      date: 2024-01-01
      tags:
      - a
      - b
      draft: false
    YAML
  end

  let(:block) { described_class.from_yaml(flat_yaml) }

  describe ':flat mode (default)' do
    it 'round-trips flat YAML unchanged' do
      expect(described_class.to_yaml(block)).to eq("#{flat_yaml}\n")
    end

    it 'exposes a native-typed hash via to_hash' do
      hash = described_class.to_hash(block)
      expect(hash['title']).to eq('Foo')
      expect(hash['date']).to eq(Date.new(2024, 1, 1))
      expect(hash['tags']).to eq(%w[a b])
      expect(hash['draft']).to be(false)
    end

    it 'round-trips through from_hash/to_hash' do
      hash = described_class.to_hash(block)
      back = described_class.from_hash(hash)
      expect(described_class.to_hash(back)).to eq(hash)
    end

    it 'round-trips through to_yaml/from_yaml' do
      yaml = described_class.to_yaml(block)
      back = described_class.from_yaml(yaml)
      expect(described_class.to_yaml(back)).to eq(yaml)
    end
  end

  describe ':typed mode (discriminator shape)' do
    let(:typed_yaml) { described_class.to_yaml(block, mode: :typed) }
    let(:typed_hash) { described_class.to_hash(block, mode: :typed) }

    it 'wraps string values with value_type discriminator' do
      expect(typed_hash['title']).to eq(
        'value_type' => 'string',
        'string_value' => 'Foo'
      )
    end

    it 'wraps date values with value_type discriminator' do
      expect(typed_hash['date']).to eq(
        'value_type' => 'date',
        'date_value' => '2024-01-01'
      )
    end

    it 'wraps array values with items_value discriminator' do
      expect(typed_hash['tags']).to eq(
        'value_type' => 'array',
        'items_value' => [
          { 'value_type' => 'string', 'string_value' => 'a' },
          { 'value_type' => 'string', 'string_value' => 'b' }
        ]
      )
    end

    it 'wraps boolean values with value_type discriminator' do
      expect(typed_hash['draft']).to eq(
        'value_type' => 'boolean',
        'boolean_value' => false
      )
    end

    it 'emits typed YAML with the discriminator fields' do
      expect(typed_yaml).to include('value_type: string')
      expect(typed_yaml).to include('string_value: Foo')
      expect(typed_yaml).to include('value_type: date')
      expect(typed_yaml).to include('value_type: array')
      expect(typed_yaml).to include('value_type: boolean')
    end

    it 'round-trips :typed YAML back to the same block (mode-agnostic model)' do
      back = described_class.from_yaml(typed_yaml, mode: :typed)
      expect(described_class.to_hash(back)).to eq(described_class.to_hash(block))
    end

    it 'round-trips :typed hash through from_hash(mode: :typed)' do
      back = described_class.from_hash(typed_hash, mode: :typed)
      expect(described_class.to_hash(back)).to eq(described_class.to_hash(block))
    end
  end

  describe 'mode equivalence' do
    it 'both modes share the same underlying FrontmatterBlock' do
      # Mode is purely a serialization concern — the model is mode-agnostic.
      expect(described_class.to_hash(block, mode: :flat)).to eq(
        'title' => 'Foo',
        'date' => Date.new(2024, 1, 1),
        'tags' => %w[a b],
        'draft' => false
      )
    end
  end

  describe '$schema promotion' do
    it 'promotes $schema to the block attribute, not data' do
      yaml = "$schema: https://example.com/schema.json\ntitle: Bar\n"
      block = described_class.from_yaml(yaml)
      expect(block.schema).to eq('https://example.com/schema.json')
      expect(block.data).not_to have_key('$schema')
    end

    it 'serializes $schema back to the top of the YAML' do
      block = described_class.from_yaml(
        "$schema: https://example.com/schema.json\ntitle: Bar\n"
      )
      yaml = described_class.to_yaml(block)
      # Psych quotes `$schema` because `$` is reserved at the start of a
      # YAML scalar — the quoted form is canonical.
      expect(yaml.lines.first).to start_with('"$schema":')
    end
  end

  describe 'malformed input handling' do
    it 'returns an empty block on nil' do
      block = described_class.from_yaml(nil)
      expect(block).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(block.empty?).to be(true)
    end

    it 'returns an empty block on empty string' do
      block = described_class.from_yaml('   ')
      expect(block.empty?).to be(true)
    end

    it 'returns an empty block on malformed YAML' do
      block = described_class.from_yaml("title: [unterminated")
      expect(block.empty?).to be(true)
    end

    it 'returns empty hash for non-FrontmatterBlock input' do
      expect(described_class.to_hash(Object.new)).to eq({})
      expect(described_class.to_yaml(Object.new)).to eq('')
    end

    it 'returns empty hash from from_hash with non-Hash input' do
      block = described_class.from_hash('not a hash')
      expect(block.empty?).to be(true)
    end
  end

  describe 'VitePress-shaped frontmatter (real-world SSG acceptance)' do
    it 'matches what flat YAML SSGs expect' do
      yaml = <<~YAML.strip
        title: My Post
        description: A short summary
        date: 2024-06-15
        author: Jane
      YAML
      block = described_class.from_yaml(yaml)
      hash = described_class.to_hash(block, mode: :flat)

      expect(hash['title']).to eq('My Post')
      expect(hash['description']).to eq('A short summary')
      expect(hash['date']).to eq(Date.new(2024, 6, 15))
      expect(hash['author']).to eq('Jane')
    end
  end

  describe 'integer and null values' do
    it 'wraps integer and null values correctly in typed mode' do
      yaml = "count: 42\nmissing:\n"
      block = described_class.from_yaml(yaml)
      typed = described_class.to_hash(block, mode: :typed)

      expect(typed['count']).to eq(
        'value_type' => 'integer',
        'integer_value' => 42
      )
      expect(typed['missing']).to eq('value_type' => 'null')
    end
  end
end
