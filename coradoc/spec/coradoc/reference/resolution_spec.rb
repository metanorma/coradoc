# frozen_string_literal: true

require 'spec_helper'
require 'coradoc'

RSpec.describe 'Coradoc.resolve_references (end-to-end)' do
  let(:section_a) do
    Coradoc::CoreModel::SectionElement.new(
      id: 'sec-a', title: 'Section A', level: 1,
      children: [
        Coradoc::CoreModel::ParagraphBlock.new(
          content: 'See ',
          children: [
            Coradoc::CoreModel::TextElement.new(content: 'See '),
            Coradoc::CoreModel::CrossReferenceElement.new(
              target: 'sec-b',
              id: 'xref-1',
              content: 'Section B',
              children: [
                Coradoc::CoreModel::TextElement.new(content: 'Section B')
              ]
            )
          ]
        )
      ]
    )
  end

  let(:section_b) do
    Coradoc::CoreModel::SectionElement.new(
      id: 'sec-b', title: 'Section B', level: 1, children: []
    )
  end

  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc', title: 'Doc', children: [section_a, section_b]
    )
  end

  let(:catalog) { Coradoc::Reference::Catalog::Local.from_doc(document) }
  let(:presentation) { Coradoc::Reference::Presentation::SingleDocument.new }

  it 'does not mutate the input document' do
    original_id = document.children.first.children.first.children.last.id
    Coradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      materialize: false
    )
    expect(document.children.first.children.first.children.last.id).to eq(original_id)
  end

  it 'returns a new document when materializing' do
    resolved = Coradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      materialize: true
    )
    expect(resolved).not_to be(document)
  end

  it 'materializes the cross-reference into a LinkElement' do
    resolved = Coradoc.resolve_references(
      document,
      catalog: catalog,
      presentation: presentation,
      materialize: true
    )
    inline = find_first(resolved) { |n| n.is_a?(Coradoc::CoreModel::LinkElement) }
    expect(inline).not_to be_nil
    expect(inline.target).to eq('#sec-b')
  end

  it 'handles missing policy :warn without raising' do
    catalog = Coradoc::Reference::Catalog::Local.from_doc(
      Coradoc::CoreModel::DocumentElement.new(id: 'empty', title: 'Empty', children: [])
    )
    expect do
      Coradoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        missing: :warn,
        materialize: true
      )
    end.not_to raise_error
  end

  it 'raises when missing: :error' do
    catalog = Coradoc::Reference::Catalog::Local.from_doc(
      Coradoc::CoreModel::DocumentElement.new(id: 'empty', title: 'Empty', children: [])
    )
    expect do
      Coradoc.resolve_references(
        document,
        catalog: catalog,
        presentation: presentation,
        missing: :error,
        materialize: true
      )
    end.to raise_error(Coradoc::Reference::MissingReferenceError)
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
