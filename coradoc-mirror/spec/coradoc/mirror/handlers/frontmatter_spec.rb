# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Mirror::Handlers::Frontmatter do
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe '.call' do
    it 'builds a typed entries tree from the data hash' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        schema: 'https://example.com/s.json',
        data: { 'title' => 'Hello', 'count' => 42 }
      )

      node = described_class.call(element, context: context)
      expect(node).to be_a(Coradoc::Mirror::Node::Frontmatter)
      expect(node.type).to eq('frontmatter')
      expect(node.attrs.schema).to eq('https://example.com/s.json')

      entries = node.attrs.entries
      expect(entries.length).to eq(2)

      by_key = entries.to_h { |e| [e.key, e.value] }
      expect(by_key['title'].value_type).to eq('string')
      expect(by_key['title'].string_value).to eq('Hello')
      expect(by_key['count'].value_type).to eq('integer')
      expect(by_key['count'].integer_value).to eq(42)
    end

    it 'defaults entries to empty when input has no data' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(schema: 'x')

      node = described_class.call(element, context: context)
      expect(node.attrs.entries).to eq([])
    end

    it 'encodes Date values into typed date_value' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'date' => Date.new(2026, 6, 14) }
      )

      node = described_class.call(element, context: context)
      value = node.attrs.entries.first.value
      expect(value.value_type).to eq('date')
      expect(value.date_value).to eq(Date.new(2026, 6, 14))
    end

    it 'encodes Symbol values into typed symbol_value' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'kind' => :release }
      )

      node = described_class.call(element, context: context)
      value = node.attrs.entries.first.value
      expect(value.value_type).to eq('symbol')
      expect(value.symbol_value).to eq('release')
    end

    it 'recursively encodes nested arrays of maps' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: {
          'milestones' => [
            { 'when' => Date.new(2026, 1, 1), 'tag' => :alpha },
            { 'when' => Date.new(2026, 6, 1), 'tag' => :beta }
          ]
        }
      )

      node = described_class.call(element, context: context)
      milestones = node.attrs.entries.first.value
      expect(milestones.value_type).to eq('array')
      expect(milestones.items.length).to eq(2)

      first = milestones.items.first
      expect(first.value_type).to eq('map')
      by_key = first.entries.to_h { |e| [e.key, e.value] }
      expect(by_key['when'].value_type).to eq('date')
      expect(by_key['when'].date_value).to eq(Date.new(2026, 1, 1))
      expect(by_key['tag'].value_type).to eq('symbol')
      expect(by_key['tag'].symbol_value).to eq('alpha')
    end

    it 'preserves Integer/Float/Boolean/String/nil values' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: {
          's' => 'str',
          'i' => 1,
          'f' => 3.14,
          'b' => true,
          'n' => nil
        }
      )

      node = described_class.call(element, context: context)
      by_key = node.attrs.entries.to_h { |e| [e.key, e.value] }
      expect(by_key['s'].value_type).to eq('string')
      expect(by_key['s'].string_value).to eq('str')
      expect(by_key['i'].value_type).to eq('integer')
      expect(by_key['i'].integer_value).to eq(1)
      expect(by_key['f'].value_type).to eq('float')
      expect(by_key['f'].float_value).to eq(3.14)
      expect(by_key['b'].value_type).to eq('boolean')
      expect(by_key['b'].boolean_value).to be true
      expect(by_key['n'].value_type).to eq('nil')
    end

    it 'round-trips through FrontmatterTreeToHash' do
      data = {
        'title' => 'Hello',
        'count' => 42,
        'flag' => true,
        'date' => Date.new(2026, 6, 14),
        'kind' => :release,
        'nested' => { 'a' => [1, 2] }
      }
      element = Coradoc::CoreModel::FrontmatterBlock.new(data: data)

      node = described_class.call(element, context: context)
      roundtrip = Coradoc::Mirror::FrontmatterTreeToHash.to_hash(node.attrs.entries)
      expect(roundtrip).to eq(data)
    end
  end
end
