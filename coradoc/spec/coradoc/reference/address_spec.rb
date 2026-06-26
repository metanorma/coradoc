# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Address do
  let(:address_class) { described_class }

  describe '.parse' do
    context 'when scheme is unambiguous' do
      it 'parses "#foo" as anchor' do
        addr = described_class.parse('#foo')
        expect(addr.scheme).to eq('anchor')
        expect(addr.target).to eq('foo')
      end

      it 'parses bareword "foo" as anchor' do
        addr = described_class.parse('foo')
        expect(addr.scheme).to eq('anchor')
        expect(addr.target).to eq('foo')
      end

      it 'parses "footnote-1" as anchor (no uppercase)' do
        addr = described_class.parse('footnote-1')
        expect(addr.scheme).to eq('anchor')
        expect(addr.target).to eq('footnote-1')
      end

      it 'parses "ELF-5005-1" as path' do
        addr = described_class.parse('ELF-5005-1')
        expect(addr.scheme).to eq('path')
        expect(addr.target).to eq('ELF-5005-1')
        expect(addr.fragment).to be_nil
      end

      it 'parses "ELF-5005-1#sec-3" as path with fragment' do
        addr = described_class.parse('ELF-5005-1#sec-3')
        expect(addr.scheme).to eq('path')
        expect(addr.target).to eq('ELF-5005-1')
        expect(addr.fragment).to eq('sec-3')
      end

      it 'parses "ELF:5005:1#sec-3" as scoped_path' do
        addr = described_class.parse('ELF:5005:1#sec-3')
        expect(addr.scheme).to eq('scoped_path')
        expect(addr.scope).to eq('ELF')
        expect(addr.target).to eq('5005:1')
        expect(addr.fragment).to eq('sec-3')
      end

      it 'parses https URL' do
        addr = described_class.parse('https://example.com/page')
        expect(addr.scheme).to eq('url')
        expect(addr.target).to eq('https://example.com/page')
      end

      it 'parses https URL with fragment' do
        addr = described_class.parse('https://example.com/page#frag')
        expect(addr.scheme).to eq('url')
        expect(addr.target).to eq('https://example.com/page')
        expect(addr.fragment).to eq('frag')
      end

      it 'parses DOI' do
        addr = described_class.parse('10.1234/abc')
        expect(addr.scheme).to eq('doi')
        expect(addr.target).to eq('10.1234/abc')
      end

      it 'parses ISBN with prefix' do
        addr = described_class.parse('ISBN 978-1-2-3')
        expect(addr.scheme).to eq('isbn')
        expect(addr.target).to eq('978-1-2-3')
      end
    end

    context 'when hint is provided' do
      it 'uses the hint instead of heuristic' do
        addr = described_class.parse('foo', hint: :path)
        expect(addr.scheme).to eq('path')
        expect(addr.target).to eq('foo')
      end
    end

    context 'when raw cannot be parsed' do
      it 'raises ParseError for empty string' do
        expect { described_class.parse('') }
          .to raise_error(Coradoc::Reference::Address::ParseError)
      end

      it 'raises ParseError for nil' do
        expect { described_class.parse(nil) }
          .to raise_error(Coradoc::Reference::Address::ParseError)
      end
    end
  end

  describe '#to_s (round-trip)' do
    [
      '#foo',
      'ELF-5005-1',
      'ELF-5005-1#sec-3',
      'ELF:5005:1#sec-3',
      'https://example.com/page',
      'https://example.com/page#frag',
      '10.1234/abc'
    ].each do |raw|
      it "round-trips #{raw.inspect}" do
        expect(described_class.parse(raw).to_s).to eq(raw)
      end
    end

    it 'serializes ISBN in canonical form' do
      addr = described_class.parse('ISBN 978-1-2-3')
      expect(addr.to_s).to eq('ISBN 978-1-2-3')
    end

    it 'serializes bareword anchor with leading #' do
      addr = described_class.parse('foo')
      expect(addr.to_s).to eq('#foo')
    end
  end

  describe 'value equality' do
    it 'treats equal attributes as equal' do
      a = described_class.parse('ELF-5005-1#sec-3')
      b = described_class.parse('ELF-5005-1#sec-3')
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end

    it 'distinguishes different fragments' do
      a = described_class.parse('ELF-5005-1#sec-3')
      b = described_class.parse('ELF-5005-1#sec-4')
      expect(a).not_to eq(b)
    end

    it 'distinguishes different schemes' do
      a = described_class.parse('foo')
      b = described_class.parse('foo', hint: :path)
      expect(a).not_to eq(b)
    end
  end

  describe '.register_scheme (OCP)' do
    let(:custom_scheme) do
      Module.new do
        module_function

        def scheme_name
          :custom
        end

        def matches?(raw)
          !raw.nil? && raw.to_s.start_with?('custom:')
        end

        def parse(raw)
          Coradoc::Reference::Address.new(
            scheme: 'custom',
            target: raw.to_s.delete_prefix('custom:')
          )
        end

        def serialize(address)
          "custom:#{address.target}"
        end
      end
    end

    after { described_class::Scheme.reset! }

    it 'registers and matches the custom scheme' do
      described_class.register_scheme(custom_scheme)
      addr = described_class.parse('custom:thing')
      expect(addr.scheme).to eq('custom')
      expect(addr.target).to eq('thing')
    end
  end
end
