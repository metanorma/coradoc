# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Extensions do
  after do
    described_class.clear_all
  end

  describe '.register_element' do
    it 'registers a custom element type' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      expect(described_class.registered?(:callout)).to be true
    end

    it 'returns a CustomElement instance' do
      element_class = Class.new
      result = described_class.register_element(:callout, model_class: element_class)

      expect(result).to be_a(Coradoc::Extensions::CustomElement)
    end

    it 'accepts transformers' do
      element_class = Class.new
      transformer_class = Class.new

      element = described_class.register_element(
        :callout,
        model_class: element_class,
        transformers: { html: transformer_class }
      )

      expect(element.has_transformer?(:html)).to be true
      expect(element.transformer(:html)).to eq(transformer_class)
    end

    it 'accepts serializers' do
      element_class = Class.new
      serializer_class = Class.new

      element = described_class.register_element(
        :callout,
        model_class: element_class,
        serializers: { html: serializer_class }
      )

      expect(element.has_serializer?(:html)).to be true
      expect(element.serializer(:html)).to eq(serializer_class)
    end

    it 'raises error for duplicate names' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      expect do
        described_class.register_element(:callout, model_class: element_class)
      end.to raise_error(ArgumentError, /already registered/)
    end

    it 'raises error for missing model_class' do
      expect do
        described_class.register_element(:callout, model_class: nil)
      end.to raise_error(ArgumentError, /Model class is required/)
    end

    it 'raises error for nil name' do
      element_class = Class.new
      expect do
        described_class.register_element(nil, model_class: element_class)
      end.to raise_error(ArgumentError, /name is required/)
    end
  end

  describe '.unregister_element' do
    it 'removes a registered element' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      result = described_class.unregister_element(:callout)
      expect(result).to be true
      expect(described_class.registered?(:callout)).to be false
    end

    it 'returns false for non-existent element' do
      expect(described_class.unregister_element(:nonexistent)).to be false
    end
  end

  describe '.registered?' do
    it 'returns true for registered elements' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      expect(described_class.registered?(:callout)).to be true
    end

    it 'returns false for unregistered elements' do
      expect(described_class.registered?(:nonexistent)).to be false
    end

    it 'accepts string names' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      expect(described_class.registered?('callout')).to be true
    end
  end

  describe '.get' do
    it 'returns the CustomElement for a name' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      element = described_class.get(:callout)
      expect(element).to be_a(Coradoc::Extensions::CustomElement)
      expect(element.name).to eq(:callout)
    end

    it 'returns nil for non-existent element' do
      expect(described_class.get(:nonexistent)).to be_nil
    end
  end

  describe '.element_types' do
    it 'returns list of registered element names' do
      element_class1 = Class.new
      element_class2 = Class.new

      described_class.register_element(:callout, model_class: element_class1)
      described_class.register_element(:note, model_class: element_class2)

      types = described_class.element_types
      expect(types).to contain_exactly(:callout, :note)
    end

    it 'returns empty array when no elements registered' do
      expect(described_class.element_types).to eq([])
    end
  end

  describe '.all_elements' do
    it 'returns hash of all elements' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)

      elements = described_class.all_elements
      expect(elements).to be_a(Hash)
      expect(elements.keys).to include(:callout)
    end
  end

  describe '.clear_all' do
    it 'removes all registered elements' do
      element_class = Class.new
      described_class.register_element(:callout, model_class: element_class)
      described_class.register_element(:note, model_class: element_class)

      count = described_class.clear_all
      expect(count).to eq(2)
      expect(described_class.element_types).to eq([])
    end
  end

  describe '.add_transformer' do
    it 'adds a transformer to existing element' do
      element_class = Class.new
      transformer_class = Class.new

      described_class.register_element(:callout, model_class: element_class)
      result = described_class.add_transformer(:callout, :html, transformer_class)

      expect(result).to be true
      element = described_class.get(:callout)
      expect(element.transformer(:html)).to eq(transformer_class)
    end

    it 'returns false for non-existent element' do
      transformer_class = Class.new
      result = described_class.add_transformer(:nonexistent, :html, transformer_class)

      expect(result).to be false
    end
  end

  describe '.add_serializer' do
    it 'adds a serializer to existing element' do
      element_class = Class.new
      serializer_class = Class.new

      described_class.register_element(:callout, model_class: element_class)
      result = described_class.add_serializer(:callout, :html, serializer_class)

      expect(result).to be true
      element = described_class.get(:callout)
      expect(element.serializer(:html)).to eq(serializer_class)
    end
  end

  describe '.find_transformer' do
    it 'finds transformer for model class' do
      element_class = Class.new
      transformer_class = Class.new

      described_class.register_element(
        :callout,
        model_class: element_class,
        transformers: { html: transformer_class }
      )

      found = described_class.find_transformer(element_class, :html)
      expect(found).to eq(transformer_class)
    end

    it 'finds transformer for model instance' do
      element_class = Class.new
      transformer_class = Class.new

      described_class.register_element(
        :callout,
        model_class: element_class,
        transformers: { html: transformer_class }
      )

      instance = element_class.new
      found = described_class.find_transformer(instance, :html)
      expect(found).to eq(transformer_class)
    end

    it 'returns nil when no transformer found' do
      element_class = Class.new
      found = described_class.find_transformer(element_class, :html)
      expect(found).to be_nil
    end
  end

  describe '.find_serializer' do
    it 'finds serializer for model class' do
      element_class = Class.new
      serializer_class = Class.new

      described_class.register_element(
        :callout,
        model_class: element_class,
        serializers: { html: serializer_class }
      )

      found = described_class.find_serializer(element_class, :html)
      expect(found).to eq(serializer_class)
    end
  end
end

RSpec.describe Coradoc::Extensions::CustomElement do
  describe '#initialize' do
    it 'stores element name as symbol' do
      element_class = Class.new
      element = described_class.new('callout', model_class: element_class)

      expect(element.name).to eq(:callout)
    end

    it 'stores model class' do
      element_class = Class.new
      element = described_class.new(:callout, model_class: element_class)

      expect(element.model_class).to eq(element_class)
    end

    it 'stores transformers with symbolized keys' do
      element_class = Class.new
      transformer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        transformers: { 'html' => transformer_class }
      )

      expect(element.transformers.keys).to eq([:html])
    end

    it 'stores serializers with symbolized keys' do
      element_class = Class.new
      serializer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        serializers: { 'html' => serializer_class }
      )

      expect(element.serializers.keys).to eq([:html])
    end
  end

  describe '#has_transformer?' do
    it 'returns true when transformer exists' do
      element_class = Class.new
      transformer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        transformers: { html: transformer_class }
      )

      expect(element.has_transformer?(:html)).to be true
      expect(element.has_transformer?(:adoc)).to be false
    end
  end

  describe '#has_serializer?' do
    it 'returns true when serializer exists' do
      element_class = Class.new
      serializer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        serializers: { html: serializer_class }
      )

      expect(element.has_serializer?(:html)).to be true
      expect(element.has_serializer?(:adoc)).to be false
    end
  end

  describe '#transformer' do
    it 'returns the transformer class' do
      element_class = Class.new
      transformer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        transformers: { html: transformer_class }
      )

      expect(element.transformer(:html)).to eq(transformer_class)
    end

    it 'returns nil when not found' do
      element_class = Class.new
      element = described_class.new(:callout, model_class: element_class)

      expect(element.transformer(:html)).to be_nil
    end
  end

  describe '#serializer' do
    it 'returns the serializer class' do
      element_class = Class.new
      serializer_class = Class.new

      element = described_class.new(
        :callout,
        model_class: element_class,
        serializers: { html: serializer_class }
      )

      expect(element.serializer(:html)).to eq(serializer_class)
    end
  end
end
