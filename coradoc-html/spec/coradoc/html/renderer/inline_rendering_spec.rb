# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'inline element rendering' do
  let(:renderer) { described_class.new }

  it 'renders bold as <strong>' do
    el = CoreModel::BoldElement.new(content: 'bold text')
    html = renderer.render(el)
    expect(html).to include('<strong>')
    expect(html).to include('bold text')
  end

  it 'renders italic as <em>' do
    el = CoreModel::ItalicElement.new(content: 'italic text')
    html = renderer.render(el)
    expect(html).to include('<em>')
    expect(html).to include('italic text')
  end

  it 'renders monospace as <code>' do
    el = CoreModel::MonospaceElement.new(content: 'code')
    html = renderer.render(el)
    expect(html).to include('<code>')
    expect(html).to include('code')
  end

  it 'renders link as <a href="...">' do
    el = CoreModel::LinkElement.new(target: 'https://example.com', content: 'Example')
    html = renderer.render(el)
    expect(html).to include('<a href="https://example.com"')
    expect(html).to include('Example')
  end

  it 'renders xref as <a href="#...">' do
    el = CoreModel::CrossReferenceElement.new(target: 'section1', content: 'Section 1')
    html = renderer.render(el)
    expect(html).to include('<a href="#section1"')
  end

  it 'renders superscript as <sup>' do
    el = CoreModel::SuperscriptElement.new(content: '2')
    html = renderer.render(el)
    expect(html).to include('<sup>')
    expect(html).to include('2')
  end

  it 'renders subscript as <sub>' do
    el = CoreModel::SubscriptElement.new(content: '2')
    html = renderer.render(el)
    expect(html).to include('<sub>')
  end

  it 'renders highlight as <mark>' do
    el = CoreModel::HighlightElement.new(content: 'important')
    html = renderer.render(el)
    expect(html).to include('<mark>')
  end

  it 'renders underline as <u>' do
    el = CoreModel::UnderlineElement.new(content: 'underlined')
    html = renderer.render(el)
    expect(html).to include('<u>')
  end

  it 'renders strikethrough as <del>' do
    el = CoreModel::StrikethroughElement.new(content: 'deleted')
    html = renderer.render(el)
    expect(html).to include('<del>')
  end

  it 'renders footnote inline as <sup class="footnote">' do
    el = CoreModel::FootnoteElement.new(content: 'footnote text')
    html = renderer.render(el)
    expect(html).to include('<sup')
    expect(html).to include('footnote')
  end

  it 'renders term as <span class="term">' do
    el = CoreModel::TermElement.new(content: 'API')
    html = renderer.render(el)
    expect(html).to include('<span')
    expect(html).to include('term')
    expect(html).to include('API')
  end

  it 'renders stem as <code class="stem">' do
    el = CoreModel::StemElement.new(content: 'x^2')
    html = renderer.render(el)
    expect(html).to include('<code')
    expect(html).to include('stem')
  end
end
