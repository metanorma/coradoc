# frozen_string_literal: true

require 'spec_helper'
require 'leptris'

RSpec.describe Coradoc::Html::Converters do
  describe 'Converter::Td' do
    let(:converter) { Coradoc::Html::Converters::Td.new }

    describe '#to_coradoc' do
      it 'creates a TableCell from a td element with text content' do
        html = '<td>Cell content</td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableCell)
        expect(result.content).to eq('Cell content')
        expect(result.header).to be false
      end

      it 'creates a header TableCell from a th element' do
        html = '<th>Header cell</th>'
        doc = html_fragment(html)
        node = doc.at('th')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableCell)
        expect(result.header).to be true
        expect(result.content).to eq('Header cell')
      end

      it 'extracts colspan attribute when greater than 1' do
        html = '<td colspan="3">Spanning cell</td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableCell)
        expect(result.colspan).to eq(3)
      end

      it 'ignores colspan of 1' do
        html = '<td colspan="1">Normal cell</td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result.colspan).to be_nil
      end

      it 'extracts rowspan attribute when greater than 1' do
        html = '<td rowspan="2">Tall cell</td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableCell)
        expect(result.rowspan).to eq(2)
      end

      it 'extracts alignment from align attribute' do
        html = '<td align="center">Centered</td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result.alignment).to eq('center')
      end

      it 'handles an empty td element' do
        html = '<td></td>'
        doc = html_fragment(html)
        node = doc.at('td')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableCell)
        expect(result.content).to eq('')
      end

      it 'sets tdsinglepara state when td contains a single p child' do
        html = '<td><p>Paragraph only</p></td>'
        doc = html_fragment(html)
        node = doc.at('td')
        state = {}

        converter.to_coradoc(node, state)

        expect(state[:tdsinglepara]).to be true
      end

      it 'does not set tdsinglepara state when td has mixed children' do
        html = '<td>Text <strong>bold</strong></td>'
        doc = html_fragment(html)
        node = doc.at('td')
        state = {}

        converter.to_coradoc(node, state)

        expect(state).not_to have_key(:tdsinglepara)
      end

      it 'handles th with colspan and alignment simultaneously' do
        html = '<th colspan="2" align="right">Wide header</th>'
        doc = html_fragment(html)
        node = doc.at('th')

        result = converter.to_coradoc(node, {})

        expect(result.header).to be true
        expect(result.colspan).to eq(2)
        expect(result.alignment).to eq('right')
      end
    end
  end

  describe 'Converter::Text' do
    let(:converter) { Coradoc::Html::Converters::Text.new }

    describe '#to_coradoc' do
      it 'creates a TextElement from a text node with content' do
        doc = html_fragment('<span>Hello world</span>')
        node = doc.at('span').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TextElement)
        expect(result.content).to eq('Hello world')
      end

      it 'returns nil for a whitespace-only text node' do
        doc = html_fragment('<span>   </span>')
        node = doc.at('span').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'returns nil for a blank text node' do
        doc = html_fragment('<span></span>')
        node = doc.at('span').children.first

        # An empty span has no text children at all; use the parser to
        # create an explicit empty text node
        skip('Empty elements produce no text nodes') if node.nil?

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'preserves non-breaking spaces as &nbsp; entities' do
        doc = html_fragment('<span>before after</span>')
        node = doc.at('span').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TextElement)
        expect(result.content).to include('&nbsp;')
      end

      it 'returns a single space string for a single-space text node inside a div' do
        # A text node that is exactly " " (space) is preserved as a space
        doc = html_fragment('<div> </div>')
        node = doc.at('div').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to eq(' ')
      end

      it 'returns nil for whitespace text node whose parent is ul' do
        doc = html_fragment('<ul> </ul>')
        node = doc.at('ul').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'returns nil for whitespace text node whose parent is ol' do
        doc = html_fragment('<ol> </ol>')
        node = doc.at('ol').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_nil
      end

      it 'returns nil when state[:tdsinglepara] is true and text is whitespace' do
        doc = html_fragment('<div> </div>')
        node = doc.at('div').children.first

        result = converter.to_coradoc(node, { tdsinglepara: true })

        expect(result).to be_nil
      end

      it 'removes leading and trailing newlines from text content' do
        doc = html_fragment("<span>\n\nHello\n\n</span>")
        node = doc.at('span').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TextElement)
        expect(result.content).to eq('Hello')
      end

      it 'converts inner newlines and tabs to spaces and squeezes' do
        doc = html_fragment("<span>line1\n\tline2  line3</span>")
        node = doc.at('span').children.first

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TextElement)
        expect(result.content).to eq('line1 line2 line3')
      end
    end
  end

  describe 'Converter::Tr' do
    let(:converter) { Coradoc::Html::Converters::Tr.new }

    describe '#to_coradoc' do
      it 'creates a TableRow from a tr element with td children' do
        html = '<table><tr><td>One</td><td>Two</td></tr></table>'
        doc = html_fragment(html)
        node = doc.at('tr')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableRow)
        expect(result.cells.length).to eq(2)
      end

      it 'marks the row as header when tr is the first row in a table' do
        html = '<table><tr><th>Header</th></tr></table>'
        doc = html_fragment(html)
        node = doc.at('tr')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableRow)
        expect(result.header).to be true
      end

      it 'marks the row as non-header when tr has a preceding sibling tr' do
        html = '<table><tr><td>First</td></tr><tr><td>Second</td></tr></table>'
        doc = html_fragment(html)
        rows = doc.css('tr')
        second_row = rows.last

        result = converter.to_coradoc(second_row, {})

        expect(result).to be_a(Coradoc::CoreModel::TableRow)
        expect(result.header).to be false
      end

      it 'produces TableCell entries as cell contents' do
        html = '<table><tr><td>A</td><td>B</td></tr></table>'
        doc = html_fragment(html)
        node = doc.at('tr')

        result = converter.to_coradoc(node, {})

        expect(result.cells).to all(be_a(Coradoc::CoreModel::TableCell))
      end

      it 'handles a tr with th and td children mixed' do
        html = '<table><tr><th>Label</th><td>Value</td></tr></table>'
        doc = html_fragment(html)
        node = doc.at('tr')

        result = converter.to_coradoc(node, {})

        expect(result).to be_a(Coradoc::CoreModel::TableRow)
        expect(result.cells.length).to eq(2)
        expect(result.cells.first.header).to be true
        expect(result.cells.last.header).to be false
      end
    end
  end
end
