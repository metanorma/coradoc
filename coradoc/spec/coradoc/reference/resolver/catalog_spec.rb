# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Resolver::Catalog do
  let(:target) do
    Coradoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: [])
  end

  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'Doc',
      children: [target]
    )
  end

  let(:catalog) { Coradoc::Reference::Catalog::Local.from_doc(document) }

  let(:edge) do
    Coradoc::Reference::Edge.build(
      kind: :navigation,
      address: Coradoc::Reference::Address.parse('sec-3')
    )
  end

  describe '#resolve (resolved case)' do
    it 'returns Resolved when catalog knows the address' do
      resolver = described_class.new(catalog: catalog)
      result = resolver.resolve(edge)
      expect(result).to be_a(Coradoc::Reference::Result::Resolved)
      expect(result.target).to be(target)
    end
  end

  describe '#resolve (missing case)' do
    let(:missing_edge) do
      Coradoc::Reference::Edge.build(
        kind: :navigation,
        address: Coradoc::Reference::Address.parse('missing')
      )
    end

    it 'returns Missing by default' do
      resolver = described_class.new(catalog: catalog, missing: :warn)
      result = resolver.resolve(missing_edge)
      expect(result).to be_a(Coradoc::Reference::Result::Missing)
    end

    it 'raises when missing: :error' do
      resolver = described_class.new(catalog: catalog, missing: :error)
      expect { resolver.resolve(missing_edge) }
        .to raise_error(Coradoc::Reference::MissingReferenceError)
    end
  end

  describe '#resolve (ambiguous case)' do
    let(:dup_a) do
      Coradoc::CoreModel::SectionElement.new(id: 'shared', title: 'A', level: 1, children: [])
    end
    let(:dup_b) do
      Coradoc::CoreModel::SectionElement.new(id: 'shared', title: 'B', level: 1, children: [])
    end
    let(:composite_doc_a) do
      Coradoc::CoreModel::DocumentElement.new(id: 'a', title: 'A', children: [dup_a])
    end
    let(:composite_doc_b) do
      Coradoc::CoreModel::DocumentElement.new(id: 'b', title: 'B', children: [dup_b])
    end
    let(:composite) do
      Coradoc::Reference::Catalog::Composite.new(
        Coradoc::Reference::Catalog::Local.from_doc(composite_doc_a),
        Coradoc::Reference::Catalog::Local.from_doc(composite_doc_b)
      )
    end
    let(:ambiguous_edge) do
      Coradoc::Reference::Edge.build(
        kind: :navigation,
        address: Coradoc::Reference::Address.parse('shared')
      )
    end

    it 'returns Ambiguous by default' do
      resolver = described_class.new(catalog: composite, ambiguous: :disambiguate)
      result = resolver.resolve(ambiguous_edge)
      expect(result).to be_a(Coradoc::Reference::Result::Ambiguous)
      expect(result.candidates.size).to eq(2)
    end

    it 'returns Resolved with first when ambiguous: :first' do
      resolver = described_class.new(catalog: composite, ambiguous: :first)
      result = resolver.resolve(ambiguous_edge)
      expect(result).to be_a(Coradoc::Reference::Result::Resolved)
      expect(result.target).to be(dup_a)
    end

    it 'raises when ambiguous: :error' do
      resolver = described_class.new(catalog: composite, ambiguous: :error)
      expect { resolver.resolve(ambiguous_edge) }
        .to raise_error(Coradoc::Reference::AmbiguousReferenceError)
    end
  end

  describe '#resolve (scheme mismatch)' do
    it 'returns Missing when catalog does not recognize the scheme' do
      url_edge = Coradoc::Reference::Edge.build(
        kind: :link,
        address: Coradoc::Reference::Address.parse('https://example.com')
      )
      resolver = described_class.new(catalog: catalog)
      result = resolver.resolve(url_edge)
      expect(result).to be_a(Coradoc::Reference::Result::Missing)
    end
  end
end
