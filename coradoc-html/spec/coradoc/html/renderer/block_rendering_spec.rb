# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'block rendering' do
  let(:renderer) { described_class.new }

  describe 'paragraph' do
    it 'renders as <p> with text content' do
      block = CoreModel::ParagraphBlock.new(content: 'Hello world')
      html = renderer.render(block)
      expect(html).to include('<p>')
      expect(html).to include('Hello world')
      expect(html).to include('</p>')
    end

    it 'includes id attribute' do
      block = CoreModel::ParagraphBlock.new(id: 'my-para', content: 'Text')
      html = renderer.render(block)
      expect(html).to include('id="my-para"')
    end
  end

  describe 'source code' do
    it 'renders as <pre><code> with data-lang' do
      block = CoreModel::SourceBlock.new(content: 'puts "hi"', language: 'ruby')
      html = renderer.render(block)
      expect(html).to include('<pre>')
      expect(html).to include('<code')
      expect(html).to include('data-lang="ruby"')
      expect(html).to include('puts')
    end
  end

  describe 'quote' do
    it 'renders as <blockquote>' do
      block = CoreModel::QuoteBlock.new(content: 'To be or not to be')
      html = renderer.render(block)
      expect(html).to include('<blockquote')
      expect(html).to include('To be or not to be')
    end
  end

  describe 'example' do
    it 'renders as <div class="example">' do
      block = CoreModel::ExampleBlock.new(content: 'Example content')
      html = renderer.render(block)
      expect(html).to include('<div')
      expect(html).to include('class="example"')
    end
  end

  describe 'sidebar' do
    it 'renders as <aside class="sidebar">' do
      block = CoreModel::SidebarBlock.new(content: 'Sidebar text')
      html = renderer.render(block)
      expect(html).to include('<aside')
      expect(html).to include('class="sidebar"')
    end
  end

  describe 'literal' do
    it 'renders as <pre class="literal">' do
      block = CoreModel::LiteralBlock.new(content: 'Line 1')
      html = renderer.render(block)
      expect(html).to include('<pre')
      expect(html).to include('class="literal"')
    end
  end

  describe 'listing' do
    it 'renders as <pre>' do
      block = CoreModel::ListingBlock.new(content: 'some code')
      html = renderer.render(block)
      expect(html).to include('<pre')
    end
  end

  describe 'horizontal rule' do
    it 'renders as <hr>' do
      block = CoreModel::HorizontalRuleBlock.new
      html = renderer.render(block)
      expect(html).to include('<hr>')
    end
  end

  describe 'comment block' do
    it 'renders empty (hidden)' do
      block = CoreModel::CommentBlock.new(content: 'hidden')
      html = renderer.render(block)
      expect(html.strip).to eq('')
    end
  end

  describe 'pass block' do
    it 'renders raw content without escaping' do
      block = CoreModel::PassBlock.new(content: '<custom>raw html</custom>')
      html = renderer.render(block)
      expect(html).to include('<custom>raw html</custom>')
    end
  end
end
