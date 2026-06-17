# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'
require 'coradoc/asciidoc'

RSpec.describe Coradoc::AsciiDoc::Transform::FrontmatterAttributeMap do
  describe '.entries_from_attributes' do
    it 'maps known attributes to frontmatter keys' do
      data = described_class.entries_from_attributes(
        'author' => 'Jane',
        'revdate' => '2026-06-14',
        'tags' => 'ruby docs',
        'categories' => 'tech'
      )
      expect(data.keys).to contain_exactly('author', 'date', 'tags', 'categories')
    end

    it 'produces scalar values for scalar fields' do
      data = described_class.entries_from_attributes('author' => 'Jane')
      expect(data['author']).to eq('Jane')
    end

    it 'produces arrays for tags/categories' do
      data = described_class.entries_from_attributes('tags' => 'ruby docs')
      expect(data['tags']).to eq(%w[ruby docs])
    end

    it 'drops unknown attribute keys' do
      data = described_class.entries_from_attributes('unknown' => 'x')
      expect(data).to be_empty
    end

    it 'drops empty/nil values' do
      data = described_class.entries_from_attributes('author' => '')
      expect(data).to be_empty
    end
  end

  describe '.attributes_from_block' do
    let(:yaml) do
      <<~YAML.strip
        author: Jane
        date: 2026-06-14
        tags:
          - foo
          - bar
        categories:
          - tech
        unused_field: skip me
      YAML
    end

    let(:block) { Coradoc::CoreModel::FrontmatterBlock::Codec.from_yaml(yaml) }

    it 'maps frontmatter data back to AsciiDoc attribute names' do
      attrs = described_class.attributes_from_block(block)
      expect(attrs).to include('author' => 'Jane')
      expect(attrs).to include('revdate' => '2026-06-14')
    end

    it 'serialises array data as space-separated strings' do
      attrs = described_class.attributes_from_block(block)
      expect(attrs['tags']).to eq('foo bar')
      expect(attrs['categories']).to eq('tech')
    end

    it 'drops frontmatter keys that have no attribute mapping' do
      attrs = described_class.attributes_from_block(block)
      expect(attrs).not_to have_key('unused_field')
    end
  end
end
