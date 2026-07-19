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

  it 'returns the original node unchanged' do
    node = Coradoc::CoreModel::CrossReferenceElement.new(
      target: 'sec-3', id: 'xref-1',
      children: [Coradoc::CoreModel::TextElement.new(content: 'Section 3')]
    )
    inline = materializer.materialize(
      edge: edge,
      result: result,
      node: node,
      presentation: nil,
      pages: []
    )
    expect(inline).to be(node)
  end

  it 'never degrades an image into text' do
    node = Coradoc::CoreModel::Image.new(src: 'images/pic.png', alt: 'My Alt', id: 'img-1')
    image_edge = Coradoc::Reference::Edge.build(
      kind: :image_ref,
      address: Coradoc::Reference::Address.parse('images/pic.png', hint: :path),
      label: 'My Alt'
    )
    inline = materializer.materialize(
      edge: image_edge,
      result: result,
      node: node,
      presentation: nil,
      pages: []
    )
    expect(inline).to be(node)
  end
end
