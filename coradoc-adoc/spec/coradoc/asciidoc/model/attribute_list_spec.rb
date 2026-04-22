# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::AttributeList do
  describe '#initialize' do
    it 'creates empty attribute list' do
      attrs = described_class.new

      expect(attrs.positional).to eq([])
      expect(attrs.named).to eq([])
      expect(attrs.rejected_positional).to eq([])
      expect(attrs.rejected_named).to eq([])
    end

    it 'accepts positional attributes' do
      pos = Coradoc::AsciiDoc::Model::AttributeListAttribute.new(value: 'value1')
      attrs = described_class.new(positional: [pos])

      expect(attrs.positional).to eq([pos])
    end

    it 'accepts named attributes' do
      named = Coradoc::AsciiDoc::Model::NamedAttribute.new(name: 'role', value: ['note'])
      attrs = described_class.new(named: [named])

      expect(attrs.named).to eq([named])
    end
  end

  describe '#add_positional' do
    it 'adds positional attributes' do
      attrs = described_class.new
      attrs.add_positional('value1', 'value2')

      expect(attrs.positional.size).to eq(2)
      expect(attrs.positional[0].value).to eq('value1')
      expect(attrs.positional[1].value).to eq('value2')
    end
  end

  describe '#add_named' do
    it 'adds named attribute with string value' do
      attrs = described_class.new
      attrs.add_named('role', 'note')

      expect(attrs.named.size).to eq(1)
      expect(attrs.named[0].name).to eq('role')
      expect(attrs.named[0].value).to eq(['note'])
    end

    it 'adds named attribute with array value' do
      attrs = described_class.new
      attrs.add_named('cols', %w[1 2 3])

      expect(attrs.named.size).to eq(1)
      expect(attrs.named[0].name).to eq('cols')
      expect(attrs.named[0].value).to eq(%w[1 2 3])
    end
  end

  describe '#[] and #fetch' do
    it 'returns named attribute value by name' do
      attrs = described_class.new
      attrs.add_named('role', 'note')

      expect(attrs[:role]).to eq(['note'])
      expect(attrs['role']).to eq(['note'])
    end

    it 'returns nil for missing attribute' do
      attrs = described_class.new

      expect(attrs[:missing]).to be_nil
    end

    it 'fetches with default value' do
      attrs = described_class.new

      expect(attrs.fetch(:missing, 'default')).to eq('default')
    end

    it 'fetches without default returns nil' do
      attrs = described_class.new

      expect(attrs.fetch(:missing)).to be_nil
    end
  end

  describe '#empty?' do
    it 'returns true for empty list' do
      attrs = described_class.new

      expect(attrs.empty?).to be true
    end

    it 'returns false with positional attributes' do
      attrs = described_class.new
      attrs.add_positional('value')

      expect(attrs.empty?).to be false
    end

    it 'returns false with named attributes' do
      attrs = described_class.new
      attrs.add_named('role', 'note')

      expect(attrs.empty?).to be false
    end
  end

  describe '#to_adoc' do
    it 'returns empty brackets for empty list' do
      attrs = described_class.new

      expect(attrs.to_adoc).to eq('[]')
    end

    it 'returns empty string for empty list with show_empty: false' do
      attrs = described_class.new

      expect(attrs.to_adoc(show_empty: false)).to eq('')
    end

    it 'serializes positional attributes' do
      attrs = described_class.new
      attrs.add_positional('value1', 'value2')

      expect(attrs.to_adoc).to eq('[value1,value2]')
    end

    it 'serializes named attributes' do
      attrs = described_class.new
      attrs.add_named('role', 'note')

      expect(attrs.to_adoc).to eq('[role=note]')
    end

    it 'serializes mixed attributes' do
      attrs = described_class.new
      attrs.add_positional('value1')
      attrs.add_named('role', 'note')

      expect(attrs.to_adoc).to eq('[value1,role=note]')
    end
  end

  describe 'positional_validators and named_validators' do
    it 'returns empty array for positional_validators by default' do
      attrs = described_class.new

      expect(attrs.positional_validators).to eq([])
    end

    it 'returns empty hash for named_validators by default' do
      attrs = described_class.new

      expect(attrs.named_validators).to eq({})
    end
  end
end
