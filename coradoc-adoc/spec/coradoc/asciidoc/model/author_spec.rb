# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Author do
  describe '.new' do
    it 'creates an author with all attributes' do
      author = described_class.new(
        first_name: 'John',
        middle_name: 'William',
        last_name: 'Doe',
        email: 'john.doe@example.com'
      )

      expect(author.first_name).to eq('John')
      expect(author.middle_name).to eq('William')
      expect(author.last_name).to eq('Doe')
      expect(author.email).to eq('john.doe@example.com')
    end

    it 'creates an author with minimal attributes' do
      author = described_class.new(first_name: 'Jane', last_name: 'Smith')

      expect(author.first_name).to eq('Jane')
      expect(author.last_name).to eq('Smith')
      expect(author.middle_name).to be_nil
      expect(author.email).to be_nil
    end

    it 'creates an empty author' do
      author = described_class.new

      expect(author.first_name).to be_nil
      expect(author.middle_name).to be_nil
      expect(author.last_name).to be_nil
      expect(author.email).to be_nil
    end
  end

  describe '#first_name' do
    it 'can be set and retrieved' do
      author = described_class.new
      author.first_name = 'Alice'

      expect(author.first_name).to eq('Alice')
    end
  end

  describe '#middle_name' do
    it 'can be set and retrieved' do
      author = described_class.new
      author.middle_name = 'Q'

      expect(author.middle_name).to eq('Q')
    end
  end

  describe '#last_name' do
    it 'can be set and retrieved' do
      author = described_class.new
      author.last_name = 'Builder'

      expect(author.last_name).to eq('Builder')
    end
  end

  describe '#email' do
    it 'can be set and retrieved' do
      author = described_class.new
      author.email = 'alice@example.org'

      expect(author.email).to eq('alice@example.org')
    end
  end

  describe 'inheritance' do
    it 'inherits from Coradoc::AsciiDoc::Model::Base' do
      author = described_class.new

      expect(author).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes and deserializes correctly' do
      original = described_class.new(
        first_name: 'Test',
        middle_name: 'M',
        last_name: 'User',
        email: 'test@example.com'
      )

      adoc = original.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end
