# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/reference'

RSpec.describe Coradoc::Reference::Presentation::SingleDocument do
  let(:document) do
    Coradoc::CoreModel::DocumentElement.new(
      id: 'doc',
      title: 'The Doc',
      children: [
        Coradoc::CoreModel::SectionElement.new(id: 'sec-1', title: 'Sec 1', level: 1, children: [])
      ]
    )
  end

  it 'produces a single page containing the whole document' do
    pages = described_class.new.layout(document)
    expect(pages.size).to eq(1)
    expect(pages.first.content).to be(document)
    expect(pages.first.id).to eq('doc')
    expect(pages.first.title).to eq('The Doc')
  end

  it 'locates any target on the single page' do
    presentation = described_class.new
    pages = presentation.layout(document)
    target = document.children.first
    page = presentation.locate_page(nil, target, pages: pages)
    expect(page).to be(pages.first)
  end
end
