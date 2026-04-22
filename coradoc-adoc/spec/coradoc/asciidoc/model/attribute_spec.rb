# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Attribute do
  describe '.new' do
    it 'creates an attribute with key and value' do
      attr = described_class.new(key: 'author', value: 'John Doe')

      expect(attr.key).to eq('author')
      expect(attr.value).to eq('John Doe')
    end

    it 'creates an attribute with array value' do
      attr = described_class.new(key: 'tags', value: %w[ruby asciidoc])

      expect(attr.key).to eq('tags')
      expect(attr.value).to contain_exactly('ruby', 'asciidoc')
    end

    it 'creates an attribute with default line break' do
      attr = described_class.new(key: 'test', value: 'value')

      expect(attr.line_break).to eq("\n")
    end

    it 'allows custom line break' do
      attr = described_class.new(key: 'test', value: 'value', line_break: "\r\n")

      expect(attr.line_break).to eq("\r\n")
    end
  end

  describe '#key' do
    it 'can be set and retrieved' do
      attr = described_class.new
      attr.key = 'new_key'

      expect(attr.key).to eq('new_key')
    end
  end

  describe '#value' do
    it 'can be a single value' do
      attr = described_class.new
      attr.value = 'single'

      expect(attr.value).to eq('single')
    end

    it 'can be multiple values' do
      attr = described_class.new
      attr.value = %w[one two three]

      expect(attr.value).to contain_exactly('one', 'two', 'three')
    end
  end

  describe '#line_break' do
    it 'can be customized' do
      attr = described_class.new
      attr.line_break = ''

      expect(attr.line_break).to eq('')
    end
  end

  describe 'inheritance' do
    it 'inherits from Coradoc::AsciiDoc::Model::Base' do
      attr = described_class.new

      expect(attr).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes to AsciiDoc format' do
      attr = described_class.new(key: 'author', value: ['Test Author'])

      adoc = attr.to_adoc
      expect(adoc).to be_a(String)
      expect(adoc).to include('author')
    end
  end
end
