# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::AssetResolver do
  describe '.css_link_tag' do
    it 'builds a valid link element' do
      tag = described_class.css_link_tag(stylesdir: '.', css_theme: 'default')
      expect(tag).to include('rel="stylesheet"')
      expect(tag).to include('href=')
      expect(tag).to include('default.css')
    end

    it 'includes stylesdir in href' do
      tag = described_class.css_link_tag(stylesdir: './css', css_theme: 'test')
      expect(tag).to include('css/test.css')
    end
  end

  describe '.css_style_tag' do
    it 'builds a style element' do
      tag = described_class.css_style_tag(css_theme: 'professional')
      expect(tag).to include('<style>')
      expect(tag).to include('</style>')
    end
  end

  describe '.custom_css_tag' do
    it 'builds a style element with custom CSS' do
      tag = described_class.custom_css_tag('body { color: red; }')
      expect(tag).to include('<style>')
      expect(tag).to include('body { color: red; }')
    end

    it 'returns empty string for nil' do
      expect(described_class.custom_css_tag(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.custom_css_tag('')).to eq('')
    end
  end

  describe '.js_link_tag' do
    it 'builds a script element with src and defer' do
      tag = described_class.js_link_tag
      expect(tag).to include('<script')
      expect(tag).to include('src=')
      expect(tag).to include('defer')
    end
  end

  describe '.js_script_tag' do
    it 'returns empty string when no JS asset exists' do
      tag = described_class.js_script_tag(javascript: 'nonexistent.js')
      expect(tag).to eq('')
    end
  end

  describe '.highlightjs_tags' do
    it 'builds link and script elements for highlight.js' do
      tags = described_class.highlightjs_tags(highlightjs_theme: 'github')
      expect(tags).to include('rel="stylesheet"')
      expect(tags).to include('highlight.min.js')
      expect(tags).to include('hljs.highlightAll()')
    end
  end

  describe '.embed_css?' do
    it 'embeds when linkcss is false' do
      expect(described_class.embed_css?(linkcss: false)).to be true
    end

    it 'links when linkcss is true' do
      expect(described_class.embed_css?(linkcss: true)).to be false
    end

    it 'embeds when embedded mode is true' do
      expect(described_class.embed_css?(embedded: true, linkcss: true)).to be true
    end
  end

  describe '.css_tags' do
    it 'returns embedded style when linkcss is false' do
      tags = described_class.css_tags(linkcss: false)
      expect(tags).to include('<style>')
    end

    it 'returns link tag when linkcss is true' do
      tags = described_class.css_tags(linkcss: true)
      expect(tags).to include('rel="stylesheet"')
    end
  end

  describe '.js_tags' do
    it 'returns empty string when javascript is false' do
      expect(described_class.js_tags(javascript: false)).to eq('')
    end

    it 'returns embedded script when linkjs is false' do
      tags = described_class.js_tags(linkjs: false)
      expect(tags).to include('<script')
    end

    it 'returns link tag when linkjs is true' do
      tags = described_class.js_tags(linkjs: true, linkcss: true)
      expect(tags).to include('src=')
    end
  end

  describe '.syntax_highlighter_tags' do
    it 'returns empty string when no highlighter specified' do
      expect(described_class.syntax_highlighter_tags({})).to eq('')
    end

    it 'returns highlightjs tags for highlightjs' do
      tags = described_class.syntax_highlighter_tags(source_highlighter: :highlightjs)
      expect(tags).to include('highlight.min.js')
    end

    it 'returns empty string for pygments' do
      expect(described_class.syntax_highlighter_tags(source_highlighter: :pygments)).to eq('')
    end

    it 'returns empty string for rouge' do
      expect(described_class.syntax_highlighter_tags(source_highlighter: :rouge)).to eq('')
    end
  end
end
