# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::FrontmatterBlock::Codec do
  describe '.from_yaml' do
    it 'returns empty block for nil input' do
      block = described_class.from_yaml(nil)
      expect(block).to be_a(Coradoc::CoreModel::FrontmatterBlock)
      expect(block).to be_empty
    end

    it 'returns empty block for blank input' do
      block = described_class.from_yaml("   \n  ")
      expect(block).to be_empty
    end

    it 'returns empty block for malformed YAML' do
      block = described_class.from_yaml("foo: [unclosed")
      expect(block).to be_empty
    end

    it 'returns empty block when YAML is not a hash (e.g. a list)' do
      block = described_class.from_yaml("- item1\n- item2\n")
      expect(block).to be_empty
    end

    it 'parses a string entry' do
      block = described_class.from_yaml("title: Hello\n")
      expect(block.data['title']).to eq('Hello')
    end

    it 'parses an integer entry' do
      block = described_class.from_yaml("count: 42\n")
      expect(block.data['count']).to eq(42)
    end

    it 'parses a float entry' do
      block = described_class.from_yaml("ratio: 3.14\n")
      expect(block.data['ratio']).to eq(3.14)
    end

    it 'parses a boolean entry' do
      block = described_class.from_yaml("flag: true\n")
      expect(block.data['flag']).to be true
    end

    it 'parses a null entry' do
      block = described_class.from_yaml("empty: null\n")
      expect(block.data['empty']).to be_nil
    end

    it 'parses a date entry' do
      block = described_class.from_yaml("date: 2024-07-22\n")
      expect(block.data['date']).to eq(Date.new(2024, 7, 22))
    end

    it 'parses an array entry' do
      block = described_class.from_yaml("tags:\n  - foo\n  - bar\n")
      expect(block.data['tags']).to eq(%w[foo bar])
    end

    it 'parses a nested map entry' do
      block = described_class.from_yaml("author:\n  name: Alice\n  email: a@x.com\n")
      expect(block.data['author']).to eq('name' => 'Alice', 'email' => 'a@x.com')
    end

    it 'parses an array of maps' do
      yaml = "authors:\n  - name: Alice\n  - name: Bob\n"
      block = described_class.from_yaml(yaml)
      expect(block.data['authors']).to eq([{ 'name' => 'Alice' }, { 'name' => 'Bob' }])
    end

    it 'promotes $schema to the schema attribute' do
      block = described_class.from_yaml("$schema: https://example.com/s.json\ntitle: x\n")
      expect(block.schema).to eq('https://example.com/s.json')
      expect(block.has_entry?('$schema')).to be false
      expect(block.has_entry?('title')).to be true
    end

    it 'preserves entry order' do
      block = described_class.from_yaml("zebra: 1\napple: 2\nmango: 3\n")
      expect(block.data.keys).to eq(%w[zebra apple mango])
    end
  end

  describe '.to_yaml' do
    it 'returns empty string for an empty block' do
      expect(described_class.to_yaml(Coradoc::CoreModel::FrontmatterBlock.new)).to eq('')
    end

    it 'serializes a scalar entry' do
      block = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'title' => 'Hello' }
      )
      output = described_class.to_yaml(block)
      expect(output).to include('title: Hello')
    end

    it 'serializes an integer preserving type' do
      block = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'count' => 42 }
      )
      output = described_class.to_yaml(block)
      expect(output).to include('count: 42')
      parsed = YAML.safe_load(output)
      expect(parsed['count']).to eq(42)
    end

    it 'serializes schema first when present' do
      block = Coradoc::CoreModel::FrontmatterBlock.new(
        schema: 'https://example.com/s.json',
        data: { 'title' => 'x' }
      )
      output = described_class.to_yaml(block)
      first_key = output.lines.first.to_s
      expect(first_key).to match(/\A"? \$schema "? :/x)
    end
  end

  describe 'round-trip' do
    it 'preserves complex frontmatter through from_yaml → to_yaml → from_yaml' do
      source = <<~YAML
        $schema: https://example.com/s.json
        title: Release Notes
        date: 2024-07-22
        count: 42
        flag: true
        tags:
          - foo
          - bar
        author:
          name: Alice
          email: alice@example.com
      YAML

      block1 = described_class.from_yaml(source)
      yaml_out = described_class.to_yaml(block1)
      block2 = described_class.from_yaml(yaml_out)

      expect(block2.schema).to eq(block1.schema)
      expect(block2.data.keys).to eq(block1.data.keys)
      expect(block2.data['title']).to eq('Release Notes')
      expect(block2.data['date']).to eq(Date.new(2024, 7, 22))
      expect(block2.data['count']).to eq(42)
      expect(block2.data['flag']).to be true
      expect(block2.data['tags']).to eq(%w[foo bar])
      expect(block2.data['author']).to eq(
        'name' => 'Alice', 'email' => 'alice@example.com'
      )
    end
  end
end
