# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Html::Builder do
  def build(&block)
    described_class.new(&block).to_html
  end

  describe 'element construction' do
    it 'builds a single element with attributes' do
      html = build { |doc| doc.div(class: 'element element-note') }
      expect(html).to eq('<div class="element element-note"></div>')
    end

    it 'sets text content from a positional string argument' do
      html = build { |doc| doc.title('My Title') }
      expect(html).to eq('<title>My Title</title>')
    end

    it 'nests elements via blocks' do
      html = build do |doc|
        doc.html(lang: 'en') do
          doc.head do
            doc.meta(charset: 'UTF-8')
            doc.title('X')
          end
        end
      end
      expect(html).to eq('<html lang="en"><head><meta charset="UTF-8"><title>X</title></head></html>')
    end

    it 'supports sibling top-level elements joined by newline' do
      html = build do |doc|
        doc.link(rel: 'stylesheet', href: 'a.css')
        doc.script(src: 'b.js')
      end
      expect(html).to eq('<link rel="stylesheet" href="a.css">' \
                         "\n" \
                         '<script src="b.js"></script>')
    end

    it 'adds text nodes via #text' do
      html = build { |doc| doc.p { doc.text('hello') } }
      expect(html).to eq('<p>hello</p>')
    end

    it 'inserts markup via #<< into the current element' do
      html = build { |doc| doc.body { doc << '<p>from markup</p>' } }
      expect(html).to eq('<body><p>from markup</p></body>')
    end

    it 'escapes text node content' do
      html = build { |doc| doc.p { doc.text('a < b & c') } }
      expect(html).to include('a &lt; b &amp; c')
    end
  end

  describe 'HTML serialization rules' do
    it 'serializes void elements unclosed' do
      html = build { |doc| doc.meta(name: 'x', content: 'y') }
      expect(html).to eq('<meta name="x" content="y">')
    end

    it 'emits an explicit closing tag for childless script elements' do
      html = build { |doc| doc.script(src: 'a.js', defer: '') }
      expect(html).to eq('<script src="a.js" defer=""></script>')
    end

    it 'does not escape script text content' do
      html = build { |doc| doc.script { d = 'x = 1 && 2 < 3'; doc.text(d) } }
      expect(html).to eq('<script>x = 1 && 2 < 3</script>')
    end

    it 'does not escape style text content' do
      html = build { |doc| doc.style { doc.text('a > b { color: red }') } }
      expect(html).to eq('<style>a > b { color: red }</style>')
    end
  end

  describe 'document handling' do
    it 'works without a block' do
      builder = described_class.new
      builder.div(id: 'x')
      expect(builder.to_html).to eq('<div id="x"></div>')
    end

    it 'exposes the underlying Leptris document' do
      builder = described_class.new
      expect(builder.document).to be_a(Leptris::XML::Document)
    end
  end
end
