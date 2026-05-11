# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Registry do
  let(:registry) { described_class.new }

  describe '#register' do
    it 'registers a format module' do
      format_module = Module.new

      registry.register(:test_format, format_module)

      expect(registry.registered?(:test_format)).to be true
    end

    it 'raises error for non-symbol names' do
      expect do
        registry.register('string_name', Module.new)
      end.to raise_error(ArgumentError, /must be a Symbol/)
    end

    it 'overwrites existing registration' do
      first = Module.new
      second = Module.new

      registry.register(:format, first)
      registry.register(:format, second)

      expect(registry.get(:format)).to eq(second)
    end
  end

  describe '#get' do
    it 'returns the registered format module' do
      format_module = Module.new
      registry.register(:my_format, format_module)

      expect(registry.get(:my_format)).to eq(format_module)
    end

    it 'returns nil for unregistered format' do
      expect(registry.get(:unknown)).to be_nil
    end
  end

  describe '#[]' do
    it 'is an alias for #get' do
      format_module = Module.new
      registry.register(:my_format, format_module)

      expect(registry[:my_format]).to eq(format_module)
    end
  end

  describe '#registered?' do
    it 'returns true for registered format' do
      registry.register(:registered, Module.new)

      expect(registry.registered?(:registered)).to be true
    end

    it 'returns false for unregistered format' do
      expect(registry.registered?(:unregistered)).to be false
    end
  end

  describe '#list' do
    it 'returns empty array when no formats registered' do
      expect(registry.list).to eq([])
    end

    it 'returns list of registered format names' do
      registry.register(:format1, Module.new)
      registry.register(:format2, Module.new)

      expect(registry.list).to contain_exactly(:format1, :format2)
    end
  end

  describe '#size' do
    it 'returns count of registered formats' do
      expect(registry.size).to eq(0)

      registry.register(:format1, Module.new)
      expect(registry.size).to eq(1)

      registry.register(:format2, Module.new)
      expect(registry.size).to eq(2)
    end
  end

  describe '#clear' do
    it 'removes all registered formats' do
      registry.register(:format1, Module.new)
      registry.register(:format2, Module.new)

      registry.clear

      expect(registry.size).to eq(0)
      expect(registry.list).to eq([])
    end
  end

  describe '#each' do
    it 'iterates over registered formats' do
      format1 = Module.new
      format2 = Module.new
      registry.register(:format1, format1)
      registry.register(:format2, format2)

      results = []
      registry.each do |name, mod|
        results << [name, mod]
      end

      expect(results).to contain_exactly(
        [:format1, format1],
        [:format2, format2]
      )
    end

    it 'returns enumerator when no block given' do
      registry.register(:format, Module.new)

      expect(registry.each).to be_an(Enumerator)
    end
  end

  describe '#each_value' do
    it 'iterates over item values' do
      mod1 = Module.new
      mod2 = Module.new
      registry.register(:a, mod1)
      registry.register(:b, mod2)

      values = []
      registry.each_value { |v| values << v }

      expect(values).to contain_exactly(mod1, mod2)
    end
  end

  describe '#each_key' do
    it 'iterates over item names' do
      registry.register(:x, Module.new)
      registry.register(:y, Module.new)

      keys = []
      registry.each_key { |k| keys << k }

      expect(keys).to contain_exactly(:x, :y)
    end
  end

  describe '#options_for' do
    it 'returns options for a registered item' do
      registry.register(:fmt, Module.new, extensions: ['.txt'])

      expect(registry.options_for(:fmt)).to eq(extensions: ['.txt'])
    end

    it 'returns nil for unregistered item' do
      expect(registry.options_for(:missing)).to be_nil
    end
  end

  describe '#define' do
    it 'registers a self-identifying item via processor_id' do
      processor = Module.new do
        def self.processor_id
          :auto_format
        end
      end

      registry.define(processor)

      expect(registry.get(:auto_format)).to eq(processor)
      expect(registry.registered?(:auto_format)).to be true
    end

    it 'raises NoMethodError for items without processor_id' do
      expect { registry.define(Module.new) }.to raise_error(NoMethodError)
    end
  end

  describe '#for_file' do
    it 'finds item whose processor_match? returns true' do
      processor = Module.new do
        def self.processor_match?(filename)
          filename.end_with?('.html')
        end
      end
      registry.register(:html, processor)

      expect(registry.for_file('page.html')).to eq(processor)
    end

    it 'returns nil when no item matches' do
      registry.register(:text, Module.new)
      expect(registry.for_file('page.html')).to be_nil
    end

    it 'returns nil when no items registered' do
      expect(registry.for_file('page.html')).to be_nil
    end
  end

  describe '#process' do
    let(:processor) do
      Module.new do
        def self.processor_id
          :proc_test
        end

        def self.processor_match?(filename)
          filename.end_with?('.test')
        end

        def self.processor_execute(content, _options)
          "processed: #{content}"
        end
      end
    end

    before do
      registry.define(processor)
    end

    it 'finds and executes by format' do
      result = registry.process('input', format: :proc_test)
      expect(result).to eq('processed: input')
    end

    it 'finds and executes by filename' do
      result = registry.process('input', filename: 'doc.test')
      expect(result).to eq('processed: input')
    end

    it 'raises ArgumentError when no item matches' do
      expect { registry.process('x', format: :missing) }.to raise_error(ArgumentError, /No processor found/)
    end

    it 'uses custom error_label' do
      custom = described_class.new(error_label: 'my handler')
      expect { custom.process('x', format: :missing) }.to raise_error(ArgumentError, /No my handler found/)
    end
  end

  describe '#items' do
    it 'returns the internal items hash' do
      mod = Module.new
      registry.register(:test, mod)
      expect(registry.items).to eq(test: mod)
    end
  end
end

RSpec.describe Coradoc do
  describe '.registry' do
    it 'returns a Registry instance' do
      expect(described_class.registry).to be_a(Coradoc::Registry)
    end

    it 'returns the same instance on repeated calls' do
      expect(described_class.registry).to eq(described_class.registry)
    end
  end

  describe '.register_format' do
    it 'registers a format with the global registry' do
      format_module = Module.new

      described_class.register_format(:test_format, format_module)

      expect(described_class.registered_formats).to include(:test_format)
    end
  end

  describe '.get_format' do
    it 'gets a registered format' do
      format_module = Module.new
      described_class.register_format(:my_format, format_module)

      expect(described_class.get_format(:my_format)).to eq(format_module)
    end
  end

  describe '.registered_formats' do
    it 'returns list of registered format names' do
      expect(described_class.registered_formats).to be_an(Array)
    end
  end
end
