# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::Registry do
  before do
    described_class.clear
  end

  after do
    described_class.clear
  end

  describe '.register' do
    it 'registers a transformer for a class' do
      transformer = ->(model) { "transformed: #{model}" }
      described_class.register(String, transformer)

      expect(described_class.registered?(String)).to be true
    end

    it 'stores the transformer in the registry' do
      transformer = lambda(&:upcase)
      described_class.register(String, transformer)

      expect(described_class.lookup(String)).to eq(transformer)
    end
  end

  describe '.lookup' do
    it 'returns the transformer for a registered class' do
      transformer = ->(model) { model * 2 }
      described_class.register(Integer, transformer)

      expect(described_class.lookup(Integer)).to eq(transformer)
    end

    it 'returns nil for unregistered classes' do
      expect(described_class.lookup(String)).to be_nil
    end

    it 'walks up the inheritance chain' do
      parent_transformer = ->(model) { "parent: #{model}" }
      described_class.register(Numeric, parent_transformer)

      expect(described_class.lookup(Integer)).to eq(parent_transformer)
    end

    it 'prefers exact match over parent class' do
      parent_transformer = ->(_model) { 'parent' }
      child_transformer = ->(_model) { 'child' }

      described_class.register(Numeric, parent_transformer)
      described_class.register(Integer, child_transformer)

      expect(described_class.lookup(Integer)).to eq(child_transformer)
      expect(described_class.lookup(Float)).to eq(parent_transformer)
    end
  end

  describe '.transform' do
    it 'transforms a model using the registered transformer' do
      described_class.register(String, lambda(&:upcase))

      result = described_class.transform('hello')
      expect(result).to eq('HELLO')
    end

    it 'returns the model unchanged if no transformer found' do
      result = described_class.transform('unchanged')
      expect(result).to eq('unchanged')
    end

    it 'transforms arrays by mapping each element' do
      described_class.register(String, lambda(&:upcase))

      result = described_class.transform(%w[a b c])
      expect(result).to eq(%w[A B C])
    end

    it 'returns nil unchanged' do
      expect(described_class.transform(nil)).to be_nil
    end
  end

  describe '.registered?' do
    it 'returns true for registered classes' do
      described_class.register(String, ->(s) { s })

      expect(described_class.registered?(String)).to be true
    end

    it 'returns false for unregistered classes' do
      expect(described_class.registered?(String)).to be false
    end

    it 'returns true for child classes of registered parents' do
      described_class.register(Numeric, ->(n) { n })

      expect(described_class.registered?(Integer)).to be true
    end
  end

  describe '.clear' do
    it 'removes all registrations' do
      described_class.register(String, ->(s) { s })
      described_class.clear

      expect(described_class.registered?(String)).to be false
    end
  end

  describe '.registered_classes' do
    it 'returns all registered classes' do
      described_class.register(String, ->(s) { s })
      described_class.register(Integer, ->(n) { n })

      classes = described_class.registered_classes
      expect(classes).to contain_exactly(String, Integer)
    end
  end

  describe '.register_with_priority' do
    it 'registers with priority for subclass handling' do
      parent_transformer = ->(_model) { 'parent' }
      child_transformer = ->(_model) { 'child' }

      described_class.register_with_priority(Numeric, parent_transformer, priority: 0)
      described_class.register_with_priority(Integer, child_transformer, priority: 10)

      # Higher priority should be checked first
      result = described_class.transform(42)
      expect(result).to eq('child')
    end
  end

  describe 'with CoreModel classes' do
    it 'transforms AsciiDoc models to CoreModel' do
      described_class.register(
        Coradoc::AsciiDoc::Model::Inline::Bold,
        lambda { |model|
          Coradoc::CoreModel::InlineElement.new(
            format_type: 'bold',
            content: model.content
          )
        }
      )

      bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')
      result = described_class.transform(bold)

      expect(result).to be_a(Coradoc::CoreModel::InlineElement)
      expect(result.format_type).to eq('bold')
      expect(result.content).to eq('bold text')
    end
  end
end
