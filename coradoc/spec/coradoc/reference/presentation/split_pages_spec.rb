# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Presentation::SplitPages do
  let(:section_a) do
    Coradoc::CoreModel::SectionElement.new(
      id: 'sec-a', title: 'Section A', level: 1,
      children: [
        Coradoc::CoreModel::ParagraphBlock.new(content: 'In A')
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
      id: 'doc',
      title: 'Doc',
      children: [section_a, section_b]
    )
  end

  it 'produces one page per top-level section' do
    pages = described_class.new(split_at: :section).layout(document)
    expect(pages.size).to eq(2)
    expect(pages.map(&:id)).to contain_exactly('sec-a', 'sec-b')
  end

  it 'locates the page for a target inside a section' do
    presentation = described_class.new
    pages = presentation.layout(document)
    target = section_a.children.first
    page = presentation.locate_page(nil, target, pages: pages)
    expect(page.id).to eq('sec-a')
  end

  it 'locates the page for a section itself' do
    presentation = described_class.new
    pages = presentation.layout(document)
    page = presentation.locate_page(nil, section_b, pages: pages)
    expect(page.id).to eq('sec-b')
  end

  context 'when document has no children' do
    let(:empty_doc) do
      Coradoc::CoreModel::DocumentElement.new(id: 'empty', title: 'Empty', children: [])
    end

    it 'produces a single page for the root' do
      pages = described_class.new.layout(empty_doc)
      expect(pages.size).to eq(1)
      expect(pages.first.content).to be(empty_doc)
    end
  end
end
