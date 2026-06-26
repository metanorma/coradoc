# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Materializer::NavigationHtml do
  let(:target) do
    Coradoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: [])
  end
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc', children: [target]
    )
  end

  let(:presentation) { Coradoc::Reference::Presentation::SingleDocument.new }
  let(:pages) { presentation.layout(document) }
  let(:address) { Coradoc::Reference::Address.parse('sec-3') }
  let(:edge) do
    Coradoc::Reference::Edge.build(
      kind: :navigation, address: address, label: 'Section 3'
    )
  end
  let(:resolved_result) do
    Coradoc::Reference::Result::Resolved.build(
      edge: edge, address: address, target: target
    )
  end

  let(:materializer) { described_class.new }

  it 'produces a LinkElement pointing at the located page' do
    inline = materializer.materialize(
      edge: edge,
      result: resolved_result,
      presentation: presentation,
      pages: pages
    )
    expect(inline).to be_a(Coradoc::CoreModel::LinkElement)
    expect(inline.target).to eq('#sec-3')
  end

  it 'uses the edge label as visible text' do
    inline = materializer.materialize(
      edge: edge,
      result: resolved_result,
      presentation: presentation,
      pages: pages
    )
    expect(inline.content).to eq('Section 3')
  end

  it 'falls back to the address when result is Missing' do
    missing = Coradoc::Reference::Result::Missing.build(edge: edge, address: address)
    inline = materializer.materialize(
      edge: edge,
      result: missing,
      presentation: presentation,
      pages: pages
    )
    expect(inline).to be_a(Coradoc::CoreModel::LinkElement)
    expect(inline.target).to eq(address.to_s)
  end
end
