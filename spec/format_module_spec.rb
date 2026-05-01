# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/format_module'

RSpec.describe Coradoc::FormatModule do
  describe '.validate!' do
    it 'returns true for a module with parse_to_core and serialize' do
      mod = Module.new do
        def self.parse_to_core(_input); end
        def self.serialize(_model, **_opts); end
      end

      expect(described_class.validate!(mod, :test)).to be true
    end

    it 'returns true for a module with parse (not parse_to_core) and serialize' do
      mod = Module.new do
        def self.parse(_input); end
        def self.serialize(_model, **_opts); end
      end

      expect(described_class.validate!(mod, :test)).to be true
    end

    it 'warns and returns false when serialize is missing' do
      mod = Module.new do
        def self.parse_to_core(_input); end
      end

      expect { described_class.validate!(mod, :incomplete) }.to output(/missing: serialize/).to_stderr
    end

    it 'warns and returns false when both parse methods are missing' do
      mod = Module.new do
        def self.serialize(_model, **_opts); end
      end

      expect { described_class.validate!(mod, :incomplete) }.to output(/missing: parse_to_core or parse/).to_stderr
    end

    it 'warns about all missing methods when neither parse nor serialize exist' do
      mod = Module.new {}

      expect { described_class.validate!(mod, :empty) }.to output(/missing: parse_to_core or parse, serialize/).to_stderr
    end
  end

  describe 'registration validation' do
    it 'validates format modules when registered' do
      incomplete_mod = Module.new do
        def self.serialize(_model, **_opts); end
      end

      expect { Coradoc.register_format(:test_incomplete, incomplete_mod) }
        .to output(/missing: parse_to_core or parse/).to_stderr

      # Clean up
      Coradoc.registry.send(:items).delete(:test_incomplete)
    end
  end
end
