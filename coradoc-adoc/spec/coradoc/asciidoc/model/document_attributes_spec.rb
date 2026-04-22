# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::DocumentAttributes do
  describe '.new' do
    it 'creates empty document attributes' do
      attrs = described_class.new

      expect(attrs.data).to be_nil.or be_empty
    end

    it 'creates document attributes with data' do
      attr1 = Coradoc::AsciiDoc::Model::Attribute.new(key: 'author', value: 'John Doe')
      attr2 = Coradoc::AsciiDoc::Model::Attribute.new(key: 'version', value: '1.0')
      attrs = described_class.new(data: [attr1, attr2])

      expect(attrs.data).to contain_exactly(attr1, attr2)
    end
  end

  describe '#data' do
    it 'can be assigned' do
      attrs = described_class.new
      attr = Coradoc::AsciiDoc::Model::Attribute.new(key: 'title', value: 'My Document')
      attrs.data = [attr]

      expect(attrs.data).to include(attr)
    end
  end

  describe '#to_hash' do
    it 'returns empty hash for empty attributes' do
      attrs = described_class.new

      expect(attrs.to_hash).to eq({})
    end

    it 'converts attributes to hash' do
      attrs = described_class.new
      attrs.data = [
        Coradoc::AsciiDoc::Model::Attribute.new(key: 'author', value: 'Jane Doe'),
        Coradoc::AsciiDoc::Model::Attribute.new(key: 'email', value: 'jane@example.com')
      ]

      result = attrs.to_hash

      expect(result).to eq({
                             'author' => 'Jane Doe',
                             'email' => 'jane@example.com'
                           })
    end

    it 'handles nil data gracefully' do
      attrs = described_class.new
      attrs.data = nil

      expect(attrs.to_hash).to eq({})
    end
  end

  describe '#get_attribute' do
    it 'returns attribute value by name' do
      attrs = described_class.new
      attrs.data = [Coradoc::AsciiDoc::Model::Attribute.new(key: 'version', value: '2.0')]

      expect(attrs.get_attribute('version')).to eq('2.0')
    end

    it 'returns nil for non-existent attribute' do
      attrs = described_class.new

      expect(attrs.get_attribute('nonexistent')).to be_nil
    end

    it 'finds attribute by symbol name' do
      attrs = described_class.new
      attrs.data = [Coradoc::AsciiDoc::Model::Attribute.new(key: 'title', value: 'Test')]

      expect(attrs.get_attribute(:title)).to eq('Test')
    end

    it 'handles nil data gracefully' do
      attrs = described_class.new
      attrs.data = nil

      expect(attrs.get_attribute('any')).to be_nil
    end
  end

  describe 'inheritance' do
    it 'inherits from Coradoc::AsciiDoc::Model::Base' do
      attrs = described_class.new

      expect(attrs).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end
