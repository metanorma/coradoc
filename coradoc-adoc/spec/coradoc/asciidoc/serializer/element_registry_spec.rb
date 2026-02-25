# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Serializer::ElementRegistry do
  # Use before/after hooks (not let) to ensure serializers are captured
  # before any test runs and restored after all tests complete
  # rubocop:disable RSpec/BeforeAfterAll, RSpec/InstanceVariable
  before(:all) do
    @original_serializers = described_class.registered_models.each_with_object({}) do |model_class, memo|
      memo[model_class] = described_class.get(model_class)
    end
  end

  after(:all) do
    described_class.clear!
    @original_serializers.each do |model_class, serializer_class|
      described_class.register(model_class, serializer_class) if serializer_class
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll, RSpec/InstanceVariable

  describe '.override' do
    it 'replaces an existing serializer and returns previous' do
      # Ensure serializers are loaded
      Coradoc::AsciiDoc::Serializer::Registrations.load_all!

      original = described_class.get(Coradoc::AsciiDoc::Model::Paragraph)
      expect(original).not_to be_nil

      custom_class = Class.new do
        def to_adoc(model, _options = {})
          "CUSTOM: #{model.content}"
        end
      end

      previous = described_class.override(Coradoc::AsciiDoc::Model::Paragraph, custom_class)

      expect(previous).to eq(original)
      expect(described_class.get(Coradoc::AsciiDoc::Model::Paragraph)).to eq(custom_class)
    end

    it 'returns nil when overriding unregistered class' do
      custom_class = Class.new
      model_class = Class.new

      previous = described_class.override(model_class, custom_class)

      expect(previous).to be_nil
      expect(described_class.get(model_class)).to eq(custom_class)
    end
  end

  describe '.get' do
    before do
      Coradoc::AsciiDoc::Serializer::Registrations.load_all!
    end

    it 'returns nil for unregistered class' do
      expect(described_class.get(String)).to be_nil
    end

    it 'returns serializer for registered class' do
      # Paragraph should be registered
      expect(described_class.get(Coradoc::AsciiDoc::Model::Paragraph)).not_to be_nil
    end
  end

  describe '.register' do
    it 'registers a serializer for a model class' do
      custom_class = Class.new
      model_class = Class.new

      described_class.register(model_class, custom_class)

      expect(described_class.get(model_class)).to eq(custom_class)
    end
  end

  describe '.unregister' do
    it 'removes a registered serializer' do
      custom_class = Class.new
      model_class = Class.new

      described_class.register(model_class, custom_class)
      described_class.unregister(model_class)

      expect(described_class.get(model_class)).to be_nil
    end

    it 'returns the removed serializer' do
      custom_class = Class.new
      model_class = Class.new

      described_class.register(model_class, custom_class)
      result = described_class.unregister(model_class)

      expect(result).to eq(custom_class)
    end
  end

  describe '.lookup' do
    before do
      Coradoc::AsciiDoc::Serializer::Registrations.load_all!
    end

    it 'returns serializer for registered class' do
      result = described_class.lookup(Coradoc::AsciiDoc::Model::Paragraph)
      expect(result).not_to be_nil
    end

    it 'raises ArgumentError for unregistered class' do
      expect do
        described_class.lookup(String)
      end.to raise_error(ArgumentError, /No serializer registered/)
    end
  end

  describe '.registered?' do
    before do
      Coradoc::AsciiDoc::Serializer::Registrations.load_all!
    end

    it 'returns true for registered class' do
      expect(described_class.registered?(Coradoc::AsciiDoc::Model::Paragraph)).to be true
    end

    it 'returns false for unregistered class' do
      expect(described_class.registered?(String)).to be false
    end
  end

  describe '.registered_models' do
    before do
      Coradoc::AsciiDoc::Serializer::Registrations.load_all!
    end

    it 'returns array of registered model classes' do
      models = described_class.registered_models
      expect(models).to be_an(Array)
      expect(models).to include(Coradoc::AsciiDoc::Model::Paragraph)
    end
  end
end
