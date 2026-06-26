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

  describe 'flat YAML round-trip' do
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

  describe 'typed value preservation via Psych permitted classes' do
    it 'preserves Date through round-trip' do
      block = described_class.from_yaml("due: 2024-06-15\n")
      expect(described_class.to_hash(block)['due']).to eq(Date.new(2024, 6, 15))
    end

    it 'preserves Time through round-trip' do
      block = described_class.from_yaml("at: 2024-06-15T10:30:00Z\n")
      expect(described_class.to_hash(block)['at']).to be_a(Time)
    end

    it 'preserves Symbol through round-trip' do
      block = described_class.from_yaml("status: :draft\n")
      expect(described_class.to_hash(block)['status']).to eq(:draft)
    end

    it 'preserves Integer through round-trip' do
      block = described_class.from_yaml("count: 42\n")
      expect(described_class.to_hash(block)['count']).to eq(42)
    end

    it 'preserves Boolean through round-trip' do
      block = described_class.from_yaml("draft: false\n")
      expect(described_class.to_hash(block)['draft']).to eq(false)
    end

    it 'preserves nil through round-trip' do
      block = described_class.from_yaml("missing:\n")
      hash = described_class.to_hash(block)
      expect(hash.key?('missing')).to be(true)
      expect(hash['missing']).to be_nil
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

    it 'warns and returns an empty block on malformed YAML' do
      allow(Coradoc::Logger).to receive(:warn)
      block = described_class.from_yaml('title: [unterminated')
      expect(Coradoc::Logger).to have_received(:warn).with(/frontmatter parse failed/)
      expect(block.empty?).to be(true)
    end

    it 'warns and returns an empty block on disallowed YAML class' do
      allow(Coradoc::Logger).to receive(:warn)
      block = described_class.from_yaml('foo: !ruby/object:Object {}')
      expect(Coradoc::Logger).to have_received(:warn).with(/frontmatter parse failed/)
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
      hash = described_class.to_hash(block)

      expect(hash['title']).to eq('My Post')
      expect(hash['description']).to eq('A short summary')
      expect(hash['date']).to eq(Date.new(2024, 6, 15))
      expect(hash['author']).to eq('Jane')
    end
  end

  describe 'nested structures' do
    it 'preserves nested Hash values' do
      yaml = <<~YAML.strip
        author:
          name: Jane
          email: jane@example.com
      YAML
      block = described_class.from_yaml(yaml)
      hash = described_class.to_hash(block)
      expect(hash['author']).to eq(
        'name' => 'Jane',
        'email' => 'jane@example.com'
      )
    end

    it 'preserves Array of Hashes' do
      yaml = <<~YAML.strip
        authors:
        - name: Jane
        - name: Carlos
      YAML
      block = described_class.from_yaml(yaml)
      hash = described_class.to_hash(block)
      expect(hash['authors']).to eq([
        { 'name' => 'Jane' },
        { 'name' => 'Carlos' }
      ])
    end
  end
end
