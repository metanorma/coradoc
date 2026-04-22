# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/serializer/registry'

RSpec.describe Coradoc::Serializer::Registry do
  before { described_class.clear }

  let(:base_serializer) { Coradoc::Serializer::Base }

  describe '.register' do
    it 'registers a serializer for a model class' do
      model_class = String

      described_class.register(model_class, base_serializer)

      expect(described_class.registry).to have_key('String')
    end

    it 'returns the previous serializer when overriding' do
      first_serializer = Class.new
      second_serializer = Class.new

      described_class.register(String, first_serializer)
      previous = described_class.register(String, second_serializer)

      expect(previous).to eq(first_serializer)
    end
  end

  describe '.unregister' do
    it 'removes a registered serializer' do
      described_class.register(String, base_serializer)
      described_class.unregister(String)

      expect(described_class.registry).not_to have_key('String')
    end

    it 'returns the removed serializer' do
      described_class.register(String, base_serializer)
      removed = described_class.unregister(String)

      expect(removed).to eq(base_serializer)
    end
  end

  describe '.lookup' do
    it 'finds a serializer by model instance' do
      described_class.register(String, base_serializer)

      result = described_class.lookup('test string')

      expect(result).to eq(base_serializer)
    end

    it 'finds a serializer by model class' do
      described_class.register(String, base_serializer)

      result = described_class.lookup(String)

      expect(result).to eq(base_serializer)
    end

    it 'returns nil for unregistered models' do
      result = described_class.lookup({})

      expect(result).to be_nil
    end

    it 'checks parent classes when not directly registered' do
      parent_class = Class.new
      child_class = Class.new(parent_class)

      described_class.register(parent_class, base_serializer)

      result = described_class.lookup(child_class.new)

      expect(result).to eq(base_serializer)
    end
  end

  describe '.registered?' do
    it 'returns true for registered models' do
      described_class.register(String, base_serializer)

      expect(described_class.registered?(String)).to be true
    end

    it 'returns false for unregistered models' do
      expect(described_class.registered?(Hash)).to be false
    end
  end

  describe '.registered_models' do
    it 'returns all registered model class names' do
      described_class.register(String, base_serializer)
      described_class.register(Integer, base_serializer)

      models = described_class.registered_models

      expect(models).to include('String')
      expect(models).to include('Integer')
    end
  end

  describe '.clear' do
    it 'removes all registrations' do
      described_class.register(String, base_serializer)
      described_class.register(Integer, base_serializer)

      described_class.clear

      expect(described_class.registry).to be_empty
    end
  end

  describe '.serialize' do
    it 'serializes using registered serializer' do
      custom_serializer = Class.new(base_serializer) do
        def serialize(element, **)
          "SERIALIZED: #{element}"
        end
      end

      described_class.register(String, custom_serializer)

      result = described_class.serialize('test')

      expect(result).to eq('SERIALIZED: test')
    end

    it 'returns nil for unregistered models' do
      result = described_class.serialize({ key: 'value' })

      expect(result).to be_nil
    end

    it 'passes format option to serializer' do
      custom_serializer = Class.new(base_serializer) do
        def serialize(element, format:, **)
          "FORMAT: #{format}, DATA: #{element}"
        end
      end

      described_class.register(String, custom_serializer)

      result = described_class.serialize('test', format: :html)

      expect(result).to eq('FORMAT: html, DATA: test')
    end

    it 'passes additional options to serializer' do
      custom_serializer = Class.new(base_serializer) do
        def serialize(element, **options)
          "OPTS: #{options.inspect}, DATA: #{element}"
        end
      end

      described_class.register(String, custom_serializer)

      result = described_class.serialize('test', format: :adoc, indent: 2)

      expect(result).to include('indent')
      expect(result).to include('2')
    end
  end
end

RSpec.describe Coradoc::Serializer::Base do
  describe '#serialize' do
    it 'returns string representation by default' do
      serializer = described_class.new

      result = serializer.serialize('test element')

      expect(result).to eq('test element')
    end
  end

  describe '.serialize' do
    it 'creates instance and calls serialize' do
      result = described_class.serialize('test')

      expect(result).to eq('test')
    end
  end
end
