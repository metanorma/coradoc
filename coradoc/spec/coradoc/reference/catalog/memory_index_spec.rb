# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Catalog::MemoryIndex do
  let(:address) { Coradoc::Reference::Address.parse('sec-1') }
  let(:content_a) do
    Coradoc::CoreModel::SectionElement.new(id: 'sec-1', title: 'A', level: 1, children: [])
  end
  let(:content_b) do
    Coradoc::CoreModel::SectionElement.new(id: 'sec-1', title: 'B', level: 1, children: [])
  end

  it 'returns the single content for a unique address' do
    index = described_class.new
    index.add(address, content_a)
    expect(index.lookup(address)).to be(content_a)
  end

  it 'returns all contents for an ambiguous address' do
    index = described_class.new
    index.add(address, content_a).add(address, content_b)
    expect(index.lookup(address)).to eq([content_a, content_b])
    expect(index.ambiguous?(address)).to be(true)
  end

  it 'returns nil for an unknown address' do
    index = described_class.new
    expect(index.lookup(address)).to be_nil
  end

  it 'does not leak internal storage for external mutation' do
    index = described_class.new
    index.add(address, content_a).add(address, content_b)
    entries = index.lookup(address)
    entries << 'INJECTED'
    expect(index.lookup(address)).to eq([content_a, content_b])
  end

  it 'tracks schemes of indexed addresses' do
    index = described_class.new
    index.add(address, content_a)
    expect(index.recognizes_scheme?(:anchor)).to be(true)
    expect(index.recognizes_scheme?(:doi)).to be(false)
  end

  it 'requires an Address and content' do
    index = described_class.new
    expect { index.add('sec-1', content_a) }.to raise_error(ArgumentError)
    expect { index.add(address, nil) }.to raise_error(ArgumentError)
  end

  it 'enumerates every address-content pair' do
    index = described_class.new
    index.add(address, content_a).add(address, content_b)
    pairs = index.each_pair.to_a
    expect(pairs).to eq([[address, content_a], [address, content_b]])
  end
end
