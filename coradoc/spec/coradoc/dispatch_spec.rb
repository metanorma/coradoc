# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::Dispatch do
  let(:base_class) do
    Class.new do
      def self.name = 'BaseClass'
    end
  end

  let(:derived_class) do
    Class.new(base_class) do
      def self.name = 'DerivedClass'
    end
  end

  let(:other_class) do
    Class.new do
      def self.name = 'OtherClass'
    end
  end

  describe '.strict' do
    it 'returns the handler for an exact key match' do
      dispatch = described_class.strict
      handler = :handler
      dispatch.register(base_class, handler)
      expect(dispatch.lookup(base_class)).to be(handler)
    end

    it 'returns nil on miss without raising' do
      dispatch = described_class.strict
      expect(dispatch.lookup(other_class)).to be_nil
    end

    it 'does not walk ancestors' do
      dispatch = described_class.strict
      dispatch.register(base_class, :base_handler)
      expect(dispatch.lookup(derived_class)).to be_nil
    end

    it 'raises Coradoc::Error on lookup! miss' do
      dispatch = described_class.strict
      expect { dispatch.lookup!(other_class) }.to raise_error(Coradoc::Error)
    end
  end

  describe '.hierarchical' do
    it 'walks ancestors when the exact class has no entry' do
      dispatch = described_class.hierarchical
      dispatch.register(base_class, :base_handler)
      expect(dispatch.lookup(derived_class)).to eq(:base_handler)
    end

    it 'prefers the exact class entry over the ancestor entry' do
      dispatch = described_class.hierarchical
      dispatch.register(base_class, :base_handler)
      dispatch.register(derived_class, :derived_handler)
      expect(dispatch.lookup(derived_class)).to eq(:derived_handler)
    end

    it 'returns nil when no ancestor has an entry' do
      dispatch = described_class.hierarchical
      expect(dispatch.lookup(derived_class)).to be_nil
    end
  end

  describe '#override' do
    it 'replaces the entry and returns the previous handler' do
      dispatch = described_class.strict
      dispatch.register(base_class, :original)
      previous = dispatch.override(base_class, :replacement)
      expect(previous).to eq(:original)
      expect(dispatch.lookup(base_class)).to eq(:replacement)
    end

    it 'returns nil when overriding a key with no prior entry' do
      dispatch = described_class.strict
      previous = dispatch.override(base_class, :first)
      expect(previous).to be_nil
    end
  end

  describe '#unregister' do
    it 'removes the entry' do
      dispatch = described_class.strict
      dispatch.register(base_class, :handler)
      dispatch.unregister(base_class)
      expect(dispatch.registered?(base_class)).to be(false)
    end
  end

  describe '#registered_keys' do
    it 'lists the registered keys' do
      dispatch = described_class.strict
      dispatch.register(base_class, :one)
      dispatch.register(other_class, :two)
      expect(dispatch.registered_keys).to contain_exactly(base_class, other_class)
    end
  end

  describe '#clear!' do
    it 'empties the registry' do
      dispatch = described_class.strict
      dispatch.register(base_class, :handler)
      dispatch.clear!
      expect(dispatch.registered_keys).to be_empty
    end
  end

  describe 'default block' do
    it 'is invoked on miss when configured' do
      dispatch = described_class.new { |key| "default-for-#{key}" }
      expect(dispatch.lookup(:missing)).to eq('default-for-missing')
    end
  end
end
