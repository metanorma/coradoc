# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Base do
  # Create a concrete test class since Base is abstract
  let(:test_class) do
    Class.new(Coradoc::CoreModel::Base) do
      attribute :name, :string
      attribute :value, :integer

      private

      def comparable_attributes
        super + %i[name value]
      end
    end
  end

  describe '.new' do
    it 'creates an instance with attributes' do
      instance = test_class.new(id: 'test-1', title: 'Test', name: 'Example', value: 42)

      expect(instance.id).to eq('test-1')
      expect(instance.title).to eq('Test')
      expect(instance.name).to eq('Example')
      expect(instance.value).to eq(42)
    end

    it 'creates an instance with default metadata' do
      instance = test_class.new

      expect(instance.metadata).to eq({})
    end
  end

  describe '#semantically_equivalent?' do
    let(:instance1) { test_class.new(id: 'test', title: 'Title', name: 'Name', value: 10) }
    let(:instance2) { test_class.new(id: 'test', title: 'Title', name: 'Name', value: 10) }
    let(:instance3) { test_class.new(id: 'other', title: 'Title', name: 'Name', value: 10) }
    let(:instance4) { test_class.new(id: 'test', title: 'Different', name: 'Name', value: 10) }

    it 'returns true for identical attributes' do
      expect(instance1.semantically_equivalent?(instance2)).to be true
    end

    it 'returns false for different attributes' do
      expect(instance1.semantically_equivalent?(instance4)).to be false
    end

    it 'returns false for different classes' do
      other = double('other')
      expect(instance1.semantically_equivalent?(other)).to be false
    end
  end

  describe 'inheritance' do
    it 'allows subclasses to define additional attributes' do
      subclass = Class.new(test_class) do
        attribute :extra, :string
      end

      instance = subclass.new(name: 'Test', value: 1, extra: 'Extra value')

      expect(instance.name).to eq('Test')
      expect(instance.value).to eq(1)
      expect(instance.extra).to eq('Extra value')
    end
  end

  describe 'Lutaml::Model integration' do
    it 'serializes to hash' do
      instance = test_class.new(id: 'test-1', name: 'Example', value: 42)
      hash = instance.to_hash

      expect(hash['id']).to eq('test-1')
      expect(hash['name']).to eq('Example')
      expect(hash['value']).to eq(42)
    end
  end
end
