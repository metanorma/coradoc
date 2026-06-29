# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::InlineTransformVisitor do
  let(:to_core_model) { Coradoc::AsciiDoc::Transform::ToCoreModel }
  let(:visitor) { described_class.new(to_core_model) }

  def tc(text)
    Coradoc::CoreModel::TextContent.new(text: text)
  end

  describe '#transform' do
    context 'with nil' do
      it 'returns empty array' do
        expect(visitor.transform(nil)).to eq([])
      end
    end

    context 'with String' do
      it 'wraps non-empty string in TextContent' do
        result = visitor.transform('hello')
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::TextContent)
        expect(result.first.text).to eq('hello')
      end

      it 'returns empty array for empty string' do
        expect(visitor.transform('')).to eq([])
      end
    end

    context 'with TextElement' do
      it 'unwraps TextElement and recurses into content' do
        te = Coradoc::AsciiDoc::Model::TextElement.new(content: 'inner text')
        result = visitor.transform(te)
        expect(result.length).to eq(1)
        expect(result.first.text).to eq('inner text')
      end

      it 'handles array content inside TextElement' do
        te = Coradoc::AsciiDoc::Model::TextElement.new(
          content: ['hello', ' world']
        )
        result = visitor.transform(te)
        expect(result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.to_s }.join).to include('hello')
      end
    end

    context 'with Term' do
      it 'produces a TermElement' do
        term = Coradoc::AsciiDoc::Model::Term.new(term: 'API')
        result = visitor.transform(term)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::TermElement)
        expect(result.first.content).to eq('API')
      end
    end

    context 'with inline formatting models' do
      it 'transforms Bold through ToCoreModel' do
        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')
        result = visitor.transform(bold)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::BoldElement)
      end

      it 'transforms Italic through ToCoreModel' do
        italic = Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic')
        result = visitor.transform(italic)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::ItalicElement)
      end

      it 'transforms Monospace through ToCoreModel' do
        mono = Coradoc::AsciiDoc::Model::Inline::Monospace.new(content: 'code')
        result = visitor.transform(mono)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::MonospaceElement)
      end

      it 'transforms Link through ToCoreModel' do
        link = Coradoc::AsciiDoc::Model::Inline::Link.new(
          path: 'https://example.com', name: 'Example'
        )
        result = visitor.transform(link)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::LinkElement)
      end
    end

    context 'with Array' do
      it 'transforms each item' do
        items = [
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold'),
          Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic')
        ]
        result = visitor.transform(items)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::CoreModel::BoldElement)
        expect(result.last).to be_a(Coradoc::CoreModel::ItalicElement)
      end

      it 'inserts space between adjacent TextElements when previous ended with a line break' do
        te1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'hello', line_break: "\n")
        te2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'world')
        result = visitor.transform([te1, te2])
        texts = result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.content.to_s }
        expect(texts).to eq(['hello', ' ', 'world'])
      end

      it 'does not insert space between adjacent TextElements on the same line' do
        te1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'hello')
        te2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'world')
        result = visitor.transform([te1, te2])
        texts = result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.content.to_s }
        expect(texts).to eq(['hello', 'world'])
      end

      it 'does not insert space before first item' do
        te = Coradoc::AsciiDoc::Model::TextElement.new(content: 'solo')
        result = visitor.transform([te])
        texts = result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.content.to_s }
        expect(texts).to eq(['solo'])
      end

      it 'skips empty transformations' do
        items = ['hello', '', 'world']
        result = visitor.transform(items)
        texts = result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.content.to_s }
        expect(texts).to eq(%w[hello world])
      end

      it 'does not insert space when line_break is +' do
        te1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'line1')
        te2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'line2', line_break: '+')
        result = visitor.transform([te1, te2])
        texts = result.map { |r| r.is_a?(Coradoc::CoreModel::TextContent) ? r.text : r.content.to_s }
        expect(texts).not_to include(' ')
      end

      # Soft-break spaces must only be synthesised between two
      # adjacent TextElements — i.e. real source line breaks. When
      # an inline element (Bold, Passthrough, Image, etc.) sits
      # between two TextElements, the source had them on the same
      # line, so no space should be synthesised. Without this guard,
      # `Before +pass:[RAW]+ after` would emit a double space around
      # the passthrough, and `foo +\nbar` (hard break) would emit a
      # stray space between the hard break and "bar".
      it 'does not insert space around an inline element between TextElements' do
        items = [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Before '),
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'middle'),
          Coradoc::AsciiDoc::Model::TextElement.new(content: ' after')
        ]
        result = visitor.transform(items)
        text_contents = result.select { |r| r.is_a?(Coradoc::CoreModel::TextContent) }
        expect(text_contents.map(&:text)).to eq(['Before ', ' after'])
      end

      it 'does not insert space between TextElement and Passthrough' do
        items = [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Before '),
          Coradoc::AsciiDoc::Model::Inline::Passthrough.new(content: 'RAW')
        ]
        result = visitor.transform(items)
        text_contents = result.select { |r| r.is_a?(Coradoc::CoreModel::TextContent) }
        expect(text_contents.map(&:text)).to eq(['Before '])
      end
    end

    context 'with unknown type' do
      it 'falls back to text extraction for non-AsciiDoc types' do
        tc = Coradoc::CoreModel::TextContent.new(text: 'fallback')
        result = visitor.transform(tc)
        expect(result.length).to eq(1)
        expect(result.first).to be_a(Coradoc::CoreModel::TextContent)
        expect(result.first.text).to eq('fallback')
      end
    end

    context 'with mixed content' do
      it 'handles strings and models together' do
        items = [
          'plain text',
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
        ]
        result = visitor.transform(items)
        expect(result.length).to eq(2)
        expect(result.first).to be_a(Coradoc::CoreModel::TextContent)
        expect(result.last).to be_a(Coradoc::CoreModel::BoldElement)
      end
    end
  end
end
