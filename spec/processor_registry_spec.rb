# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::ProcessorRegistry do
  let(:test_registry) do
    mod = Module.new
    mod.extend(described_class)
    mod.error_label = 'test processor'
    mod
  end

  let(:sample_processor) do
    Module.new do
      def self.processor_id
        :test
      end

      def self.processor_match?(filename)
        filename.end_with?('.test')
      end

      def self.processor_execute(content, _options)
        "processed: #{content}"
      end
    end
  end

  describe '#define' do
    it 'registers a processor' do
      test_registry.define(sample_processor)
      expect(test_registry.processors).to include(test: sample_processor)
    end

    it 'raises NoMethodError for modules without processor_id' do
      expect { test_registry.define(Module.new) }.to raise_error(NoMethodError)
    end
  end

  describe '#get' do
    it 'retrieves by symbol' do
      test_registry.define(sample_processor)
      expect(test_registry.get(:test)).to eq(sample_processor)
    end

    it 'returns nil for unknown' do
      expect(test_registry.get(:unknown)).to be_nil
    end
  end

  describe '#[]' do
    it 'aliases to get' do
      test_registry.define(sample_processor)
      expect(test_registry[:test]).to eq(sample_processor)
    end
  end

  describe '#registered?' do
    it 'returns true when registered' do
      test_registry.define(sample_processor)
      expect(test_registry).to be_registered(:test)
    end

    it 'returns false when not registered' do
      expect(test_registry).not_to be_registered(:unknown)
    end
  end

  describe '#for_file' do
    it 'finds matching processor' do
      test_registry.define(sample_processor)
      expect(test_registry.for_file('doc.test')).to eq(sample_processor)
    end

    it 'returns nil when no match' do
      expect(test_registry.for_file('doc.txt')).to be_nil
    end
  end

  describe '#process' do
    it 'dispatches to the right processor' do
      test_registry.define(sample_processor)
      result = test_registry.process('input', format: :test)
      expect(result).to eq('processed: input')
    end

    it 'raises with custom error label' do
      expect { test_registry.process('x', format: :missing) }
        .to raise_error(ArgumentError, /No test processor found/)
    end
  end

  describe '#registry' do
    it 'returns a Registry instance' do
      expect(test_registry.registry).to be_a(Coradoc::Registry)
    end

    it 'shares state between define and registry' do
      test_registry.define(sample_processor)
      expect(test_registry.registry.get(:test)).to eq(sample_processor)
    end
  end
end
