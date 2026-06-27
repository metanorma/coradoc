# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Coradoc::Html::Converters do
  describe 'Converter::Li' do
    let(:converter) { Coradoc::Html::Converters::Li.new }

    describe '#to_coradoc' do
      it 'creates a ListItem from an li element with text content' do
        html = '<li>Simple item</li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
      end

      it 'preserves id attribute on the li element' do
        html = '<li id="item-1">Item with ID</li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.id).to eq('item-1')
      end

      it 'extracts content from a single nested p tag directly' do
        html = '<li><p>Paragraph in list item</p></li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.children).not_to be_empty
      end

      it 'processes children directly when li has multiple non-p children' do
        html = '<li>First <strong>bold</strong> last</li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.children.length).to be >= 2
      end

      it 'handles an empty li element' do
        html = '<li></li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
      end

      it 'handles li with multiple p children by treating all children' do
        html = '<li><p>First paragraph</p><p>Second paragraph</p></li>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('li')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::ListItem)
        expect(result.children.length).to be >= 2
      end
    end
  end

  describe 'Converter::Mark' do
    let(:converter) { Coradoc::Html::Converters::Mark.new }

    describe '#to_coradoc' do
      it 'creates a HighlightElement from a mark element with text' do
        html = '<mark>highlighted text</mark>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('mark')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::HighlightElement)
      end

      it 'returns content directly when mark is nested inside another mark' do
        html = '<mark><mark>inner</mark></mark>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('mark > mark')

        result = converter.to_coradoc(node, {})

        # When inside an ancestor mark, the Markup base class returns
        # content directly rather than wrapping again
        expect(result).not_to be_nil
      end

      it 'handles an empty mark element' do
        html = '<mark></mark>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('mark')

        result = converter.to_coradoc(node, {})

        # Empty mark returns nil (no children, no leading whitespace)
        expect(result).to be_nil
      end

      it 'preserves text content within the highlight element via nested_elements' do
        html = '<mark>important</mark>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('mark')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::HighlightElement)
        # Markup converter places text into nested_elements, not content
        expect(result.nested_elements).not_to be_empty
        text_elem = result.nested_elements.find { |e| e.is_a?(Coradoc::CoreModel::TextElement) }
        expect(text_elem).not_to be_nil
        expect(text_elem.content).to include('important')
      end
    end
  end

  describe 'Converter::PassThrough' do
    let(:converter) { Coradoc::Html::Converters::PassThrough.new }

    describe '#to_coradoc' do
      it 'returns the raw HTML string for an element' do
        html = '<custom>Hello</custom>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('custom')

        result = converter.to_coradoc(node, {})

        expect(result).to eq('<custom>Hello</custom>')
      end

      it 'returns the raw HTML string including attributes' do
        html = '<custom class="special" data-x="1">Content</custom>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('custom')

        result = converter.to_coradoc(node, {})

        expect(result).to include('custom')
        expect(result).to include('Content')
      end

      it 'returns an empty tag string for a self-closing element' do
        html = '<br/>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('br')

        result = converter.to_coradoc(node, {})

        expect(result).to include('br')
      end

      it 'returns the full serialized HTML for nested elements' do
        html = '<outer><inner>nested</inner></outer>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('outer')

        result = converter.to_coradoc(node, {})

        expect(result).to include('<inner>nested</inner>')
      end
    end
  end

  describe 'Converter::Sub' do
    let(:converter) { Coradoc::Html::Converters::Sub.new }

    describe '#to_coradoc' do
      it 'creates a SubscriptElement from a sub element with text' do
        html = '<sub>2</sub>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sub')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SubscriptElement)
      end

      it 'returns nil for an empty sub element' do
        html = '<sub></sub>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sub')

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'stores child content in the subscript element' do
        html = '<sub>H2O</sub>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sub')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SubscriptElement)
        # PositionalFormatting passes content (array of TextElements) to the
        # element constructor; the :string attribute stores stringified refs
        expect(result.content).to be_a(Array)
        expect(result.content).not_to be_empty
        expect(result.content.first).to include('TextElement')
      end

      it 'returns an array with whitespace when sub has leading/trailing whitespace' do
        html = 'before<sub> 2 </sub>after'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sub')

        result = converter.to_coradoc(node, {})

        # With leading/trailing whitespace, result is an array:
        # [leading_whitespace, SubscriptElement, trailing_whitespace]
        elements = Array(result)
        sub_elem = elements.find { |e| e.is_a?(Coradoc::CoreModel::SubscriptElement) }
        expect(sub_elem).not_to be_nil
      end

      it 'formats_type is subscript' do
        html = '<sub>2</sub>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sub')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SubscriptElement)
        expect(result.class.format_type).to eq('subscript')
      end
    end
  end

  describe 'Converter::Sup' do
    let(:converter) { Coradoc::Html::Converters::Sup.new }

    describe '#to_coradoc' do
      it 'creates a SuperscriptElement from a sup element with text' do
        html = '<sup>2</sup>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sup')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SuperscriptElement)
      end

      it 'returns nil for an empty sup element' do
        html = '<sup></sup>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sup')

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'stores child content in the superscript element' do
        html = '<sup>nd</sup>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sup')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SuperscriptElement)
        # PositionalFormatting passes content (array of TextElements) to the
        # element constructor; the :string attribute stores stringified refs
        expect(result.content).to be_a(Array)
        expect(result.content).not_to be_empty
        expect(result.content.first).to include('TextElement')
      end

      it 'returns an array with whitespace when sup has leading/trailing whitespace' do
        html = 'text<sup> 2 </sup>more'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sup')

        result = converter.to_coradoc(node, {})

        elements = Array(result)
        sup_elem = elements.find { |e| e.is_a?(Coradoc::CoreModel::SuperscriptElement) }
        expect(sup_elem).not_to be_nil
      end

      it 'formats_type is superscript' do
        html = '<sup>2</sup>'
        doc = Nokogiri::HTML.fragment(html)
        node = doc.at('sup')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::SuperscriptElement)
        expect(result.class.format_type).to eq('superscript')
      end
    end
  end
end
