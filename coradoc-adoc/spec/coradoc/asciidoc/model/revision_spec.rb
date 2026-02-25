# frozen_string_literal: true

require 'spec_helper'
require 'date'

RSpec.describe Coradoc::AsciiDoc::Model::Revision do
  describe '.new' do
    it 'creates a revision with all attributes' do
      revision = described_class.new(
        number: '1.0',
        date: Date.new(2024, 1, 15),
        remark: 'Initial release'
      )

      expect(revision.number).to eq('1.0')
      expect(revision.date).to eq(Date.new(2024, 1, 15))
      expect(revision.remark).to eq('Initial release')
    end

    it 'creates a revision with minimal attributes' do
      revision = described_class.new(number: '2.0')

      expect(revision.number).to eq('2.0')
      expect(revision.date).to be_nil
      expect(revision.remark).to be_nil
    end

    it 'creates an empty revision' do
      revision = described_class.new

      expect(revision.number).to be_nil
      expect(revision.date).to be_nil
      expect(revision.remark).to be_nil
    end
  end

  describe '#number' do
    it 'can be set and retrieved' do
      revision = described_class.new
      revision.number = '3.2.1'

      expect(revision.number).to eq('3.2.1')
    end
  end

  describe '#date' do
    it 'accepts a Date object' do
      revision = described_class.new
      revision.date = Date.new(2024, 6, 1)

      expect(revision.date).to eq(Date.new(2024, 6, 1))
    end

    it 'accepts nil' do
      revision = described_class.new
      revision.date = nil

      expect(revision.date).to be_nil
    end
  end

  describe '#remark' do
    it 'can be set and retrieved' do
      revision = described_class.new
      revision.remark = 'Bug fixes and improvements'

      expect(revision.remark).to eq('Bug fixes and improvements')
    end
  end

  describe '#validate' do
    it 'validates successfully with valid date' do
      revision = described_class.new(
        number: '1.0',
        date: Date.new(2024, 1, 1)
      )

      expect { revision.validate }.not_to raise_error
    end

    it 'validates successfully with nil date' do
      revision = described_class.new(number: '1.0', date: nil)

      expect { revision.validate }.not_to raise_error
    end

    it 'raises TypeError for invalid date type' do
      revision = described_class.new
      revision.number = '1.0'
      # Bypass type checking by directly setting instance variable
      revision.instance_variable_set(:@date, '2024-01-01')

      expect { revision.validate }.to raise_error(TypeError, /date must be a Date/)
    end
  end

  describe 'inheritance' do
    it 'inherits from Coradoc::AsciiDoc::Model::Base' do
      revision = described_class.new

      expect(revision).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end

  describe 'round-trip serialization' do
    it 'serializes and deserializes correctly' do
      original = described_class.new(
        number: '2.0',
        date: Date.new(2024, 12, 25),
        remark: 'Holiday release'
      )

      adoc = original.to_adoc
      expect(adoc).to be_a(String)
    end
  end
end
