# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/inline_element_drop'

RSpec.describe Coradoc::Html::Drop::InlineElementDrop do
  let(:model) { CoreModel::InlineElement.new }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#template_type' do
    it 'returns inline_element' do
      expect(drop.template_type).to eq('inline_element')
    end
  end

  describe '#format_type' do
    it 'returns bold for BoldElement' do
      bold = CoreModel::BoldElement.new(content: [CoreModel::TextContent.new(text: 'bold')])
      drop = described_class.new(bold)
      expect(drop.format_type).to eq('bold')
    end

    it 'returns link for LinkElement' do
      link = CoreModel::LinkElement.new(target: 'http://example.com')
      drop = described_class.new(link)
      expect(drop.format_type).to eq('link')
    end
  end

  describe '#html_tag' do
    it 'returns strong for bold' do
      bold = CoreModel::BoldElement.new(content: [CoreModel::TextContent.new(text: 'b')])
      expect(described_class.new(bold).html_tag).to eq('strong')
    end

    it 'returns em for italic' do
      italic = CoreModel::ItalicElement.new(content: [CoreModel::TextContent.new(text: 'i')])
      expect(described_class.new(italic).html_tag).to eq('em')
    end

    it 'returns code for monospace' do
      mono = CoreModel::MonospaceElement.new(content: [CoreModel::TextContent.new(text: 'm')])
      expect(described_class.new(mono).html_tag).to eq('code')
    end

    it 'returns a for link' do
      link = CoreModel::LinkElement.new(target: 'http://example.com')
      expect(described_class.new(link).html_tag).to eq('a')
    end

    it 'returns a for xref' do
      xref = CoreModel::CrossReferenceElement.new(target: 'section1')
      expect(described_class.new(xref).html_tag).to eq('a')
    end

    it 'returns sup for superscript' do
      sup = CoreModel::SuperscriptElement.new(content: [CoreModel::TextContent.new(text: '2')])
      expect(described_class.new(sup).html_tag).to eq('sup')
    end

    it 'returns sub for subscript' do
      sub = CoreModel::SubscriptElement.new(content: [CoreModel::TextContent.new(text: '2')])
      expect(described_class.new(sub).html_tag).to eq('sub')
    end

    it 'returns mark for highlight' do
      hl = CoreModel::HighlightElement.new(content: [CoreModel::TextContent.new(text: 'hl')])
      expect(described_class.new(hl).html_tag).to eq('mark')
    end

    it 'returns sup for footnote' do
      fn = CoreModel::FootnoteElement.new(target: '1')
      expect(described_class.new(fn).html_tag).to eq('sup')
    end

    it 'returns span for term' do
      term = CoreModel::TermElement.new(content: [CoreModel::TextContent.new(text: 'ref')])
      expect(described_class.new(term).html_tag).to eq('span')
    end
  end

  describe '#href' do
    it 'returns target for link' do
      link = CoreModel::LinkElement.new(target: 'http://example.com')
      expect(described_class.new(link).href).to eq('http://example.com')
    end

    it 'prefixes xref target with #' do
      xref = CoreModel::CrossReferenceElement.new(target: 'section1')
      expect(described_class.new(xref).href).to eq('#section1')
    end

    it 'returns nil for non-link types' do
      bold = CoreModel::BoldElement.new(content: [CoreModel::TextContent.new(text: 'b')])
      expect(described_class.new(bold).href).to be_nil
    end
  end

  describe '#text' do
    it 'returns escaped text content' do
      bold = CoreModel::BoldElement.new(content: [CoreModel::TextContent.new(text: '<script>bold</script>')])
      expect(described_class.new(bold).text).to eq('&lt;script&gt;bold&lt;/script&gt;')
    end
  end

  describe '#css_class' do
    it 'returns stem for stem elements' do
      stem = CoreModel::StemElement.new(content: [CoreModel::TextContent.new(text: 'x^2')])
      expect(described_class.new(stem).css_class).to eq('stem')
    end

    it 'returns term for term elements' do
      term = CoreModel::TermElement.new(content: [CoreModel::TextContent.new(text: 'ref')])
      expect(described_class.new(term).css_class).to eq('term')
    end

    it 'returns nil for bold' do
      bold = CoreModel::BoldElement.new(content: [CoreModel::TextContent.new(text: 'b')])
      expect(described_class.new(bold).css_class).to be_nil
    end
  end
end
