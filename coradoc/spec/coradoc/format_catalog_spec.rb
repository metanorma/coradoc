# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe Coradoc::FormatCatalog do
  describe '.register_format / .get_format / .registered_formats' do
    it 'maintains the format registry' do
      expect(described_class.registered_formats).to include(:asciidoc)
      expect(described_class.get_format(:asciidoc)).to be(Coradoc::AsciiDoc)
    end
  end

  describe '.detect_format' do
    it 'maps file extensions to format symbols' do
      expect(described_class.detect_format('foo.adoc')).to eq(:asciidoc)
    end

    it 'returns nil for unknown extensions' do
      expect(described_class.detect_format('foo.unknown')).to be_nil
    end
  end

  describe '.binary_format?' do
    it 'returns false for text formats' do
      expect(described_class.binary_format?(:asciidoc)).to be(false)
    end
  end

  describe '.capabilities' do
    it 'lists parse/serialize flags per format' do
      caps = described_class.capabilities
      expect(caps[:asciidoc]).to include(parse: true, serialize: true)
    end
  end

  describe '.resolve_output_format' do
    it 'returns the detected format' do
      expect(described_class.resolve_output_format('out.html')).to eq(:html)
    end

    it 'returns the default when detection fails' do
      expect(described_class.resolve_output_format(nil, default: :html)).to eq(:html)
    end
  end
end
