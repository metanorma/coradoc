# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::ReferenceMaterializers::Navigation do
  let(:target) do
    Coradoc::CoreModel::SectionElement.new(id: 'sec-3', title: 'Sec 3', level: 1, children: [])
  end

  let(:presentation) { Coradoc::Reference::Presentation::SingleDocument.new }
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

  def document
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc', children: [target]
    )
  end

  def pages
    presentation.layout(document)
  end

  it 'produces a LinkElement pointing at the located page' do
    inline = materializer.materialize(
      edge: edge,
      result: resolved_result,
      node: nil,
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
      node: nil,
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
      node: nil,
      presentation: presentation,
      pages: pages
    )
    expect(inline).to be_a(Coradoc::CoreModel::LinkElement)
    expect(inline.target).to eq(address.to_s)
  end

  context 'with SplitPages' do
    # One setup hash keeps node identities stable: the xref passed as
    # +node:+ must be the same instance the pages were laid out from.
    let(:split_setup) do
      xref = Coradoc::CoreModel::CrossReferenceElement.new(
        target: 'sec-b', id: 'xref-1',
        children: [Coradoc::CoreModel::TextElement.new(content: 'B')]
      )
      sec_a = Coradoc::CoreModel::SectionElement.new(
        id: 'sec-a', title: 'A', level: 1,
        children: [
          Coradoc::CoreModel::ParagraphBlock.new(content: 'x', children: [xref])
        ]
      )
      sec_b = Coradoc::CoreModel::SectionElement.new(id: 'sec-b', title: 'B', level: 1, children: [])
      doc = Coradoc::CoreModel::DocumentElement.new(
        id: 'doc', title: 'Doc', children: [sec_a, sec_b]
      )
      split_presentation = Coradoc::Reference::Presentation::SplitPages.new
      {
        xref: xref, section_a: sec_a, section_b: sec_b,
        presentation: split_presentation, pages: split_presentation.layout(doc)
      }
    end

    it 'prefixes the target page for cross-page references' do
      split_edge = Coradoc::Reference::Edge.build(
        kind: :navigation, address: Coradoc::Reference::Address.parse('sec-b'), label: 'B'
      )
      result = Coradoc::Reference::Result::Resolved.build(
        edge: split_edge, address: split_edge.address, target: split_setup[:section_b]
      )
      inline = materializer.materialize(
        edge: split_edge,
        result: result,
        node: split_setup[:xref],
        presentation: split_setup[:presentation],
        pages: split_setup[:pages]
      )
      expect(inline.target).to eq('sec-b#sec-b')
    end

    it 'uses a bare anchor for same-page references' do
      split_edge = Coradoc::Reference::Edge.build(
        kind: :navigation, address: Coradoc::Reference::Address.parse('sec-a'), label: 'A'
      )
      result = Coradoc::Reference::Result::Resolved.build(
        edge: split_edge, address: split_edge.address, target: split_setup[:section_a]
      )
      inline = materializer.materialize(
        edge: split_edge,
        result: result,
        node: split_setup[:xref],
        presentation: split_setup[:presentation],
        pages: split_setup[:pages]
      )
      expect(inline.target).to eq('#sec-a')
    end
  end

  describe 'end-to-end via Coradoc.resolve_references (globally registered)' do
    def e2e_document
      Coradoc::CoreModel::DocumentElement.new(
        id: 'doc', title: 'Doc',
        children: [
          Coradoc::CoreModel::SectionElement.new(
            id: 'sec-a', title: 'A', level: 1,
            children: [
              Coradoc::CoreModel::ParagraphBlock.new(
                content: 'See ',
                children: [
                  Coradoc::CoreModel::CrossReferenceElement.new(
                    target: 'sec-b', id: 'xref-1', content: 'Section B',
                    children: [Coradoc::CoreModel::TextElement.new(content: 'Section B')]
                  )
                ]
              )
            ]
          ),
          Coradoc::CoreModel::SectionElement.new(id: 'sec-b', title: 'B', level: 1, children: [])
        ]
      )
    end

    it 'materializes navigation edges into HTML LinkElements' do
      doc = e2e_document
      resolved = Coradoc.resolve_references(
        doc,
        catalog: Coradoc::Reference::Catalog::Local.from_doc(doc),
        presentation: Coradoc::Reference::Presentation::SingleDocument.new,
        format: :html,
        materialize: true
      )
      inline = find_first(resolved) { |n| n.is_a?(Coradoc::CoreModel::LinkElement) }
      expect(inline).not_to be_nil
      expect(inline.target).to eq('#sec-b')
    end
  end

  def find_first(node, &block)
    return node if yield(node)

    if node.is_a?(Coradoc::CoreModel::HasChildren) && node.children
      node.children.each do |c|
        found = find_first(c, &block)
        return found if found
      end
    end
    nil
  end
end
