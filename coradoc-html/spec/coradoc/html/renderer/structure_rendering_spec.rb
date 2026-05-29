# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'document structure rendering' do
  let(:renderer) { described_class.new }

  describe 'DocumentElement' do
    it 'renders as div.document with h1 title' do
      doc = CoreModel::DocumentElement.new(title: 'My Doc', children: [])
      html = renderer.render(doc)
      expect(html).to include('<div class="document"')
      expect(html).to include('<h1>My Doc</h1>')
    end

    it 'renders children' do
      para = CoreModel::ParagraphBlock.new(content: 'Hello')
      doc = CoreModel::DocumentElement.new(children: [para])
      html = renderer.render(doc)
      expect(html).to include('Hello')
    end
  end

  describe 'SectionElement' do
    it 'renders as <section> with heading' do
      section = CoreModel::SectionElement.new(
        title: 'Introduction',
        level: 1,
        children: []
      )
      html = renderer.render(section)
      expect(html).to include('<section')
      expect(html).to include('<h2>Introduction</h2>')
    end

    it 'offsets heading levels by +1' do
      section = CoreModel::SectionElement.new(title: 'Sub', level: 2, children: [])
      html = renderer.render(section)
      expect(html).to include('<h3>Sub</h3>')
    end

    it 'renders nested sections' do
      inner = CoreModel::SectionElement.new(title: 'Inner', level: 2, children: [])
      outer = CoreModel::SectionElement.new(title: 'Outer', level: 1, children: [inner])
      html = renderer.render(outer)
      expect(html).to include('<h2>Outer</h2>')
      expect(html).to include('<h3>Inner</h3>')
    end

    it 'includes section numbers when set via render_html5' do
      section = CoreModel::SectionElement.new(id: 's1', title: 'Intro', level: 1, children: [])
      doc = CoreModel::DocumentElement.new(children: [section])
      html = renderer.render_html5(doc, sectnums: true)
      expect(html).to include('1. Intro')
    end
  end
end
