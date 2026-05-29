# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'TOC rendering' do
  let(:renderer) { described_class.new }

  it 'renders TOC as <nav class="toc">' do
    entry = CoreModel::TocEntry.new(title: 'Intro', level: 1, id: 'intro')
    toc = CoreModel::Toc.new(entries: [entry])
    html = renderer.render(toc)
    expect(html).to include('<nav class="toc">')
    expect(html).to include('Intro')
    expect(html).to include('href="#intro"')
  end

  it 'renders numbered entries with section number' do
    entry = CoreModel::TocEntry.new(title: 'Intro', level: 1, id: 'intro', number: '1')
    toc = CoreModel::Toc.new(entries: [entry])
    html = renderer.render(toc)
    expect(html).to include('1. Intro')
  end

  it 'renders nested entries as nested <ul>' do
    child = CoreModel::TocEntry.new(title: 'Background', level: 2, id: 'bg')
    parent = CoreModel::TocEntry.new(title: 'Intro', level: 1, id: 'intro', children: [child])
    toc = CoreModel::Toc.new(entries: [parent])
    html = renderer.render(toc)
    expect(html).to include('href="#intro"')
    expect(html).to include('href="#bg"')
    expect(html.scan('<ul').size).to be >= 2
  end
end
