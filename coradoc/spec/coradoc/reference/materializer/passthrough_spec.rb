# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Materializer::Passthrough do
  let(:address) { Coradoc::Reference::Address.parse('ELF-5005-1#sec-3') }
  let(:edge) do
    Coradoc::Reference::Edge.build(
      kind: :navigation, address: address, label: 'Section 3'
    )
  end
  let(:result) do
    Coradoc::Reference::Result::Missing.build(edge: edge, address: address)
  end
  let(:materializer) { described_class.new }

  it 'produces a TextElement with the edge label' do
    inline = materializer.materialize(
      edge: edge,
      result: result,
      presentation: nil,
      pages: []
    )
    expect(inline).to be_a(Coradoc::CoreModel::TextElement)
    expect(inline.content).to eq('Section 3')
  end

  it 'falls back to the address when no label' do
    edge_no_label = Coradoc::Reference::Edge.build(kind: :navigation, address: address)
    inline = materializer.materialize(
      edge: edge_no_label,
      result: result,
      presentation: nil,
      pages: []
    )
    expect(inline.content).to eq(address.to_s)
  end
end
