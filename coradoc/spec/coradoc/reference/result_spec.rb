# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Result do
  let(:edge) do
    Coradoc::Reference::Edge.build(
      kind: :navigation,
      address: Coradoc::Reference::Address.parse('sec-3')
    )
  end

  let(:address) { edge.address }
  let(:target) { Coradoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: []) }

  describe Coradoc::Reference::Result::Resolved do
    it 'carries the target' do
      result = described_class.build(edge: edge, address: address, target: target)
      expect(result).to be_resolved
      expect(result.target).to be(target)
      expect(result.edge).to be(edge)
      expect(result.address).to eq(address)
    end
  end

  describe Coradoc::Reference::Result::Ambiguous do
    it 'carries multiple candidates' do
      other = Coradoc::CoreModel::SectionElement.new(id: 'dup', title: 'Dup', level: 1, children: [])
      result = described_class.build(edge: edge, address: address, candidates: [target, other])
      expect(result).to be_ambiguous
      expect(result.candidates.size).to eq(2)
    end
  end

  describe Coradoc::Reference::Result::Missing do
    it 'carries the address' do
      result = described_class.build(edge: edge, address: address)
      expect(result).to be_missing
      expect(result.address).to eq(address)
    end
  end

  describe Coradoc::Reference::Result::Deferred do
    it 'carries a reason' do
      result = described_class.build(edge: edge, address: address, reason: 'network')
      expect(result).to be_deferred
      expect(result.reason).to eq('network')
    end
  end

  describe 'pattern matching' do
    it 'matches Resolved' do
      result = Coradoc::Reference::Result::Resolved.build(
        edge: edge, address: address, target: target
      )
      matched = case result
                in Coradoc::Reference::Result::Resolved => r then r.target
                else nil
                end
      expect(matched).to be(target)
    end

    it 'matches Missing' do
      result = Coradoc::Reference::Result::Missing.build(edge: edge, address: address)
      matched = case result
                in Coradoc::Reference::Result::Missing => m then m.address
                else nil
                end
      expect(matched).to eq(address)
    end
  end
end
