# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Resolver::Caching do
  let(:target) do
    Coradoc::CoreModel::SectionElement.new(id: 'a', title: 'A', level: 1, children: [])
  end
  let(:address) { Coradoc::Reference::Address.parse('anchor-a') }

  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(id: 'doc', title: 'Doc', children: [target])
  end
  let(:catalog) { Coradoc::Reference::Catalog::Local.from_doc(document) }
  let(:inner) { Coradoc::Reference::Resolver::Catalog.new(catalog: catalog) }

  let(:edge) do
    Coradoc::Reference::Edge.build(kind: :navigation, address: address)
  end

  it 'memoizes by address' do
    caching = described_class.new(inner: inner)
    first = caching.resolve(edge)
    second = caching.resolve(edge)
    expect(first).to be(second)
    expect(caching.size).to eq(1)
  end

  it 'clears the cache on #clear!' do
    caching = described_class.new(inner: inner)
    caching.resolve(edge)
    expect(caching.size).to eq(1)
    caching.clear!
    expect(caching.size).to eq(0)
  end
end
