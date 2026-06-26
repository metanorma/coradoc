# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Presentation::CustomHierarchy do
  let(:section_a) do
    Coradoc::CoreModel::SectionElement.new(
      id: 'sec-a', title: 'Section A', level: 1, children: []
    )
  end
  let(:section_b) do
    Coradoc::CoreModel::SectionElement.new(
      id: 'sec-b', title: 'Section B', level: 1, children: []
    )
  end
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'Doc',
      children: [section_a, section_b]
    )
  end

  let(:hierarchy) do
    [
      { id: 'sec-a', title: 'Section A', children: [] },
      { id: 'sec-b', title: 'Section B', children: [] }
    ]
  end

  it 'produces one page per hierarchy entry, in order' do
    presentation = described_class.new(hierarchy: hierarchy)
    pages = presentation.layout(document)
    expect(pages.size).to eq(2)
    expect(pages.map(&:id)).to eq(%w[sec-a sec-b])
    expect(pages.map(&:title)).to eq(['Section A', 'Section B'])
  end

  it 'locates the page whose content matches the target' do
    presentation = described_class.new(hierarchy: hierarchy)
    pages = presentation.layout(document)
    page = presentation.locate_page(nil, section_a, pages: pages)
    expect(page.id).to eq('sec-a')
  end

  it 'nests child entries under parent' do
    nested = [
      { id: 'sec-a', title: 'A', children: [
        { id: 'sub-1', title: 'Sub', children: [] }
      ] }
    ]
    doc = Coradoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'Doc',
      children: [
        Coradoc::CoreModel::SectionElement.new(
          id: 'sec-a', title: 'A', level: 1,
          children: [
            Coradoc::CoreModel::SectionElement.new(id: 'sub-1', title: 'Sub', level: 2, children: [])
          ]
        )
      ]
    )
    presentation = described_class.new(hierarchy: nested)
    pages = presentation.layout(doc)
    expect(pages.map(&:id)).to eq(%w[sec-a sub-1])
    expect(pages.find { |p| p.id == 'sub-1' }.parent_id).to eq('sec-a')
  end
end
