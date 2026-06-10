# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::TextExtractVisitor do
  let(:visitor) { described_class.new }

  describe '#extract' do
    context 'with nil' do
      it 'returns empty string' do
        expect(visitor.extract(nil)).to eq('')
      end
    end

    context 'with String' do
      it 'returns the string' do
        expect(visitor.extract('hello')).to eq('hello')
      end

      it 'returns empty string unchanged' do
        expect(visitor.extract('')).to eq('')
      end
    end

    context 'with Parslet::Slice' do
      it 'converts to string' do
        slice = Parslet::Slice.new(0, 'sliced text')
        expect(visitor.extract(slice)).to eq('sliced text')
      end
    end

    context 'with TextElement' do
      it 'extracts string content' do
        te = Coradoc::AsciiDoc::Model::TextElement.new(content: 'plain text')
        expect(visitor.extract(te)).to eq('plain text')
      end

      it 'extracts array content' do
        te = Coradoc::AsciiDoc::Model::TextElement.new(content: ['hello', ' world'])
        expect(visitor.extract(te)).to eq('hello world')
      end
    end

    context 'with inline formatting' do
      it 'extracts bold content' do
        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold text')
        expect(visitor.extract(bold)).to eq('bold text')
      end

      it 'extracts italic content' do
        italic = Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic text')
        expect(visitor.extract(italic)).to eq('italic text')
      end

      it 'extracts monospace content' do
        mono = Coradoc::AsciiDoc::Model::Inline::Monospace.new(content: 'code')
        expect(visitor.extract(mono)).to eq('code')
      end

      it 'extracts nested formatting' do
        bold = Coradoc::AsciiDoc::Model::Inline::Bold.new(
          content: Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'both')
        )
        expect(visitor.extract(bold)).to eq('both')
      end
    end

    context 'with Term' do
      it 'extracts the term text' do
        term = Coradoc::AsciiDoc::Model::Term.new(term: 'API')
        expect(visitor.extract(term)).to eq('API')
      end
    end

    context 'with Link' do
      it 'extracts the name when present' do
        link = Coradoc::AsciiDoc::Model::Inline::Link.new(
          path: 'https://example.com', name: 'Example'
        )
        expect(visitor.extract(link)).to eq('Example')
      end

      it 'falls back to path when name is absent' do
        link = Coradoc::AsciiDoc::Model::Inline::Link.new(path: 'https://example.com')
        expect(visitor.extract(link)).to eq('https://example.com')
      end
    end

    context 'with CrossReference' do
      it 'extracts the href' do
        xref = Coradoc::AsciiDoc::Model::Inline::CrossReference.new(href: 'section-1')
        expect(visitor.extract(xref)).to eq('section-1')
      end
    end

    context 'with Stem' do
      it 'extracts the content' do
        stem = Coradoc::AsciiDoc::Model::Inline::Stem.new(content: 'x^2 + y^2')
        expect(visitor.extract(stem)).to eq('x^2 + y^2')
      end
    end

    context 'with Footnote' do
      it 'extracts footnote text' do
        footnote = Coradoc::AsciiDoc::Model::Inline::Footnote.new(text: 'A note')
        expect(visitor.extract(footnote)).to eq('A note')
      end

      it 'returns empty string when text is empty' do
        footnote = Coradoc::AsciiDoc::Model::Inline::Footnote.new
        expect(visitor.extract(footnote)).to eq('')
      end
    end

    context 'with AttributeReference' do
      it 'formats as {name}' do
        ref = Coradoc::AsciiDoc::Model::Inline::AttributeReference.new(name: 'author')
        expect(visitor.extract(ref)).to eq('{author}')
      end
    end

    context 'with CoreModel::TextContent' do
      it 'extracts the text' do
        tc = Coradoc::CoreModel::TextContent.new(text: 'core text')
        expect(visitor.extract(tc)).to eq('core text')
      end
    end

    context 'with CoreModel::Image' do
      it 'extracts alt text' do
        img = Coradoc::CoreModel::Image.new(src: 'img.png', alt: 'A picture')
        expect(visitor.extract(img)).to eq('A picture')
      end

      it 'falls back to src' do
        img = Coradoc::CoreModel::Image.new(src: 'img.png')
        expect(visitor.extract(img)).to eq('img.png')
      end
    end

    context 'with Array' do
      it 'joins items' do
        items = [
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold'),
          Coradoc::AsciiDoc::Model::Inline::Italic.new(content: 'italic')
        ]
        expect(visitor.extract(items)).to eq('bolditalic')
      end

      it 'inserts spaces between TextElements' do
        te1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'hello')
        te2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'world')
        expect(visitor.extract([te1, te2])).to eq('hello world')
      end

      it 'does not insert spaces when line_break is +' do
        te1 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'line1', line_break: '+')
        te2 = Coradoc::AsciiDoc::Model::TextElement.new(content: 'line2')
        expect(visitor.extract([te1, te2])).to eq('line1line2')
      end

      it 'skips empty items' do
        items = ['hello', '', 'world']
        expect(visitor.extract(items)).to eq('helloworld')
      end
    end

    context 'with generic Base model' do
      it 'extracts content when present' do
        model = Coradoc::AsciiDoc::Model::Inline::Highlight.new(content: 'highlighted')
        expect(visitor.extract(model)).to eq('highlighted')
      end
    end

    context 'with unknown type' do
      it 'returns empty string for non-Parslet unknowns' do
        expect(visitor.extract(42)).to eq('')
      end
    end
  end
end
