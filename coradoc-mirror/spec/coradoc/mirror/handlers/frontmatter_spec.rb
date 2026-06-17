# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Mirror::Handlers::Frontmatter do
  let(:context) { Coradoc::Mirror::CoreModelToMirror.new }

  describe '.call' do
    it 'passes schema and data through to the frontmatter node' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        schema: 'https://example.com/s.json',
        data: { 'title' => 'Hello', 'count' => 42 }
      )

      node = described_class.call(element, context: context)
      expect(node).to be_a(Coradoc::Mirror::Node::Frontmatter)
      expect(node.type).to eq('frontmatter')
      expect(node.schema).to eq('https://example.com/s.json')
      expect(node.data).to eq('title' => 'Hello', 'count' => 42)
    end

    it 'defaults data to an empty hash when input has none' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(schema: 'x')

      node = described_class.call(element, context: context)
      expect(node.data).to eq({})
    end

    it 'narrow Date values to ISO 8601 strings for JSON compatibility' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'date' => Date.new(2026, 6, 14) }
      )

      node = described_class.call(element, context: context)
      expect(node.data['date']).to eq('2026-06-14')
    end

    it 'narrow Symbol values to strings' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: { 'kind' => :release }
      )

      node = described_class.call(element, context: context)
      expect(node.data['kind']).to eq('release')
    end

    it 'recursively narrows nested arrays of dates' do
      element = Coradoc::CoreModel::FrontmatterBlock.new(
        data: {
          'milestones' => [
            { 'when' => Date.new(2026, 1, 1), 'tag' => :alpha },
            { 'when' => Date.new(2026, 6, 1), 'tag' => :beta }
          ]
        }
      )

      node = described_class.call(element, context: context)
      expect(node.data['milestones']).to eq([
        { 'when' => '2026-01-01', 'tag' => 'alpha' },
        { 'when' => '2026-06-01', 'tag' => 'beta' }
      ])
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
      expect(node.data).to eq(
        's' => 'str',
        'i' => 1,
        'f' => 3.14,
        'b' => true,
        'n' => nil
      )
    end
  end

  describe Coradoc::Mirror::Handlers::Frontmatter::JsonifiableHash do
    it 'transforms Date to ISO 8601 string' do
      expect(described_class.call(Date.new(2026, 6, 14))).to eq('2026-06-14')
    end

    it 'transforms Symbol to string' do
      expect(described_class.call(:foo)).to eq('foo')
    end

    it 'walks nested hashes and arrays' do
      input = { 'a' => [:x, { 'b' => Date.new(2026, 1, 1) }] }
      expect(described_class.call(input)).to eq(
        'a' => ['x', { 'b' => '2026-01-01' }]
      )
    end

    it 'passes Integer/Float/String/Boolean/nil through' do
      [42, 3.14, 's', true, false, nil].each do |v|
        expect(described_class.call(v)).to eq(v)
      end
    end
  end
end
