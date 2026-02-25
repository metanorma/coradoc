# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Input do
  describe '.processors' do
    it 'returns a hash' do
      expect(described_class.processors).to be_a(Hash)
    end
  end

  describe '.define' do
    it 'registers a processor' do
      test_processor = Module.new do
        def self.processor_id
          :test_format
        end
      end

      described_class.define(test_processor)

      expect(described_class.processors[:test_format]).to eq(test_processor)
    end

    it 'ignores processors without processor_id' do
      invalid_processor = Module.new

      expect { described_class.define(invalid_processor) }.not_to(change { described_class.processors.length })
    end
  end

  describe '.get' do
    before do
      @test_processor = Module.new do
        def self.processor_id
          :test_for_format
        end
      end
      described_class.define(@test_processor)
    end

    it 'returns processor by symbol ID' do
      expect(described_class.get(:test_for_format)).to eq(@test_processor)
    end

    it 'returns processor by string ID' do
      expect(described_class.get('test_for_format')).to eq(@test_processor)
    end

    it 'returns nil for unknown processor' do
      expect(described_class.get(:unknown)).to be_nil
    end
  end

  describe '.[]' do
    it 'aliases to get' do
      processor = Module.new do
        def self.processor_id
          :bracket_test
        end
      end
      described_class.define(processor)

      expect(described_class[:bracket_test]).to eq(processor)
    end
  end

  describe '.registered?' do
    before do
      @registered_processor = Module.new do
        def self.processor_id
          :registered_test
        end
      end
      described_class.define(@registered_processor)
    end

    it 'returns true for registered processor' do
      expect(described_class.registered?(:registered_test)).to be true
    end

    it 'returns false for unregistered processor' do
      expect(described_class.registered?(:not_registered)).to be false
    end
  end

  describe '.for_file' do
    before do
      @file_processor = Module.new do
        def self.processor_id
          :file_test
        end

        def self.processor_match?(filename)
          filename.end_with?('.testext')
        end
      end
      described_class.define(@file_processor)
    end

    it 'finds processor matching filename' do
      expect(described_class.for_file('document.testext')).to eq(@file_processor)
    end

    it 'returns nil when no processor matches' do
      expect(described_class.for_file('document.unknown')).to be_nil
    end
  end

  describe '.process' do
    before do
      @processable = Module.new do
        def self.processor_id
          :processable_test
        end

        def self.processor_match?(filename)
          filename.end_with?('.processable')
        end

        def self.processor_execute(input, _options)
          { processed: input.upcase }
        end
      end
      described_class.define(@processable)
    end

    it 'processes input with specified format' do
      result = described_class.process('hello', format: :processable_test)
      expect(result).to eq({ processed: 'HELLO' })
    end

    it 'processes input with auto-detected format' do
      result = described_class.process('hello', filename: 'test.processable')
      expect(result).to eq({ processed: 'HELLO' })
    end

    it 'raises error when no processor found' do
      expect do
        described_class.process('hello', format: :unknown_format)
      end.to raise_error(ArgumentError, /No input processor found/)
    end
  end
end
