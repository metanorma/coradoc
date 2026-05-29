# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/config'

RSpec.describe Coradoc::Html::Config do
  describe 'HTML builder methods' do
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
  end

  describe '.merge_options' do
    it 'merges user options with defaults' do
      options = described_class.merge_options(lang: 'ja')
      expect(options[:lang]).to eq('ja')
      expect(options[:html_version]).to eq(:html5)
    end
  end

  describe '.html_tag_for' do
    it 'maps element types to HTML tags' do
      expect(described_class.html_tag_for(:paragraph)).to eq('p')
      expect(described_class.html_tag_for(:bold)).to eq('strong')
      expect(described_class.html_tag_for(:table)).to eq('table')
    end

    it 'defaults to div for unknown types' do
      expect(described_class.html_tag_for(:unknown_xyz)).to eq('div')
    end
  end
end
