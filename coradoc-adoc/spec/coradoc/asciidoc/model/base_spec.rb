# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Base do
  # Create a simple test class that inherits from Base
  let(:test_class) do
    Class.new(described_class) do
      attribute :name, :string
      attribute :count, :integer, default: -> { 0 }
    end
  end

  describe '#initialize' do
    it 'creates instance with attributes' do
      instance = test_class.new(name: 'test')

      expect(instance.name).to eq('test')
      expect(instance.count).to eq(0)
    end

    it 'accepts default values' do
      instance = test_class.new

      expect(instance.count).to eq(0)
    end

    it 'allows overriding defaults' do
      instance = test_class.new(count: 42)

      expect(instance.count).to eq(42)
    end
  end

  describe '#to_adoc' do
    it 'is defined on Base' do
      instance = test_class.new(name: 'test')

      expect(instance).to respond_to(:to_adoc)
    end
  end

  describe '#to_h' do
    it 'converts to hash' do
      instance = test_class.new(name: 'test', count: 5)
      hash = instance.to_h

      expect(hash[:name]).to eq('test')
      expect(hash[:count]).to eq(5)
    end
  end

  describe 'inheritance' do
    it 'supports inheritance chain' do
      child_class = Class.new(test_class) do
        attribute :extra, :string
      end

      instance = child_class.new(name: 'parent', extra: 'child')

      expect(instance.name).to eq('parent')
      expect(instance.extra).to eq('child')
    end
  end
end
