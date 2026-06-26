# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

# Lightweight fake catalog used only by the chain spec. Struct-based
# because we want to inject responses for specific addresses without
# standing up a full document — this is a non-model helper, allowed.
FakeCatalog = Struct.new(:index, :schemes) do
  include Coradoc::Reference::Catalog::Protocol

  def initialize(index, schemes:)
    super(index, schemes)
  end

  def lookup(address)
    Array(index[address]).first
  end

  def each_pair(&block)
    index.each(&block) if block_given?
  end

  def recognizes_scheme?(scheme)
    Array(schemes).include?(scheme.to_sym)
  end
end

RSpec.describe Coradoc::Reference::Resolver::Chain do
  let(:target_a) do
    Coradoc::CoreModel::SectionElement.new(id: 'a', title: 'A', level: 1, children: [])
  end
  let(:target_b) do
    Coradoc::CoreModel::SectionElement.new(id: 'b', title: 'B', level: 1, children: [])
  end

  let(:address_a) { Coradoc::Reference::Address.parse('anchor-a') }
  let(:address_b) { Coradoc::Reference::Address.parse('anchor-b') }

  let(:catalog_a) { FakeCatalog.new({ address_a => target_a }, schemes: [:anchor]) }
  let(:catalog_b) { FakeCatalog.new({ address_b => target_b }, schemes: [:anchor]) }

  let(:resolver_a) do
    Coradoc::Reference::Resolver::Catalog.new(catalog: catalog_a)
  end
  let(:resolver_b) do
    Coradoc::Reference::Resolver::Catalog.new(catalog: catalog_b)
  end

  let(:chain) { described_class.new(resolver_a, resolver_b) }

  it 'returns Resolved from the first resolver when it has the target' do
    edge = Coradoc::Reference::Edge.build(kind: :navigation, address: address_a)
    result = chain.resolve(edge)
    expect(result).to be_a(Coradoc::Reference::Result::Resolved)
    expect(result.target).to be(target_a)
  end

  it 'falls through to the second resolver when first misses' do
    edge = Coradoc::Reference::Edge.build(kind: :navigation, address: address_b)
    result = chain.resolve(edge)
    expect(result).to be_a(Coradoc::Reference::Result::Resolved)
    expect(result.target).to be(target_b)
  end

  it 'returns Missing when no resolver knows the address' do
    edge = Coradoc::Reference::Edge.build(
      kind: :navigation,
      address: Coradoc::Reference::Address.parse('unknown')
    )
    result = chain.resolve(edge)
    expect(result).to be_a(Coradoc::Reference::Result::Missing)
  end
end
