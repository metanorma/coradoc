# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html'

RSpec.describe Coradoc::Html::FormatDetection do
  let(:detector) do
    mod = described_class
    Object.new.extend(mod)
  end

  describe '#html_extension?' do
    it 'matches .html files' do
      expect(detector.html_extension?('page.html')).to be true
    end

    it 'matches .htm files' do
      expect(detector.html_extension?('page.htm')).to be true
    end

    it 'matches case-insensitively' do
      expect(detector.html_extension?('PAGE.HTML')).to be true
      expect(detector.html_extension?('Page.Htm')).to be true
    end

    it 'does not match non-HTML files' do
      expect(detector.html_extension?('document.adoc')).to be false
      expect(detector.html_extension?('style.css')).to be false
      expect(detector.html_extension?('script.js')).to be false
    end

    it 'does not match files with html in the name but wrong extension' do
      expect(detector.html_extension?('html_report.txt')).to be false
    end
  end

  describe 'processor integration' do
    it 'is used by Input::Html' do
      expect(Coradoc::Input::Html.processor_match?('test.html')).to be true
      expect(Coradoc::Input::Html.processor_match?('test.adoc')).to be false
    end

    it 'is used by Output::HtmlStatic' do
      expect(Coradoc::Output::HtmlStatic.processor_match?('test.htm')).to be true
      expect(Coradoc::Output::HtmlStatic.processor_match?('test.xml')).to be false
    end

    it 'is used by Output::HtmlSpa' do
      expect(Coradoc::Output::HtmlSpa.processor_match?('test.HTML')).to be true
      expect(Coradoc::Output::HtmlSpa.processor_match?('test.pdf')).to be false
    end
  end
end
