# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Catalog::Composite do
  let(:doc_a) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc-a',
      title: 'A',
      children: [
        Coradoc::CoreModel::SectionElement.new(id: 'sec-a', title: 'Sec A', level: 1, children: [])
      ]
    )
  end

  let(:doc_b) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc-b',
      title: 'B',
      children: [
        Coradoc::CoreModel::SectionElement.new(id: 'sec-b', title: 'Sec B', level: 1, children: [])
      ]
    )
  end

  let(:catalog_a) { Coradoc::Reference::Catalog::Local.from_doc(doc_a, path: 'ELF-5005-1') }
  let(:catalog_b) { Coradoc::Reference::Catalog::Local.from_doc(doc_b, path: 'ELF-5005-2') }

  describe '#lookup' do
    it 'finds content from the first catalog' do
      composite = described_class.new(catalog_a, catalog_b)
      expect(composite.lookup(Coradoc::Reference::Address.parse('sec-a')))
        .to be(catalog_a.lookup(Coradoc::Reference::Address.parse('sec-a')))
    end

    it 'finds content from the second catalog when first misses' do
      composite = described_class.new(catalog_a, catalog_b)
      expect(composite.lookup(Coradoc::Reference::Address.parse('sec-b')))
        .to be(catalog_b.lookup(Coradoc::Reference::Address.parse('sec-b')))
    end

    it 'returns nil when no catalog knows the address' do
      composite = described_class.new(catalog_a, catalog_b)
      expect(composite.lookup(Coradoc::Reference::Address.parse('missing')))
        .to be_nil
    end

    it 'returns multiple candidates when several catalogs match' do
      # Both catalogs have a section with id "shared" — composite returns array.
      doc_c = Coradoc::CoreModel::DocumentElement.new(
        id: 'doc-c',
        title: 'C',
        children: [
          Coradoc::CoreModel::SectionElement.new(id: 'shared', title: 'C', level: 1, children: [])
        ]
      )
      doc_d = Coradoc::CoreModel::DocumentElement.new(
        id: 'doc-d',
        title: 'D',
        children: [
          Coradoc::CoreModel::SectionElement.new(id: 'shared', title: 'D', level: 1, children: [])
        ]
      )
      catalog_c = Coradoc::Reference::Catalog::Local.from_doc(doc_c)
      catalog_d = Coradoc::Reference::Catalog::Local.from_doc(doc_d)

      composite = described_class.new(catalog_c, catalog_d)
      result = composite.lookup(Coradoc::Reference::Address.parse('shared'))
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end
  end

  describe '#recognizes_scheme?' do
    it 'returns true if any child recognizes the scheme' do
      composite = described_class.new(catalog_a, catalog_b)
      expect(composite.recognizes_scheme?(:path)).to be(true)
      expect(composite.recognizes_scheme?(:anchor)).to be(true)
    end

    it 'returns false if no child recognizes the scheme' do
      composite = described_class.new(catalog_a, catalog_b)
      expect(composite.recognizes_scheme?(:url)).to be(false)
    end
  end

  describe '#each_pair' do
    it 'chains every child catalog' do
      composite = described_class.new(catalog_a, catalog_b)
      count = composite.each_pair.count
      expect(count).to be >= 4
    end
  end

  describe 'empty composite' do
    let(:composite) { described_class.new }

    it 'returns nil for any lookup' do
      expect(composite.lookup(Coradoc::Reference::Address.parse('anything')))
        .to be_nil
    end

    it 'recognizes no schemes' do
      expect(composite.recognizes_scheme?(:anchor)).to be(false)
    end

    it 'enumerates no pairs' do
      expect(composite.each_pair.count).to eq(0)
    end
  end
end
