# frozen_string_literal: true

require 'coradoc/html'
require 'coradoc/core_model'

RSpec.describe Coradoc::Html::Converters::Table do
  let(:table) { Coradoc::CoreModel::Table.new }

  describe '#to_html' do
    it 'converts a basic table to HTML' do
      table.title = 'Test Table'
      table.rows = [
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: 'Header 1'),
            Coradoc::CoreModel::TableCell.new(content: 'Header 2')
          ]
        ),
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: 'Cell 1'),
            Coradoc::CoreModel::TableCell.new(content: 'Cell 2')
          ]
        )
      ]

      html = described_class.to_html(table)

      expect(html).to include('<table')
      expect(html).to include('<caption>Test Table</caption>')
      expect(html).to include('<td>Header 1</td>')
      expect(html).to include('<td>Header 2</td>')
      expect(html).to include('<td>Cell 1</td>')
      expect(html).to include('<td>Cell 2</td>')
      expect(html).to include('</table>')
    end

    it 'converts a table without rows' do
      table.id = 'table1'
      table.rows = []

      html = described_class.to_html(table)

      expect(html).to include('<table id="table1"')
      expect(html).to include('</table>')
    end

    it 'converts a table with ID' do
      table.id = 'test-table'
      table.rows = []

      html = described_class.to_html(table)

      expect(html).to include('<table id="test-table"')
    end

    it 'escapes HTML in cell content' do
      table.rows = [
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: "<script>alert('xss')</script>")
          ]
        )
      ]

      html = described_class.to_html(table)

      expect(html).to include('&lt;script&gt;')
      expect(html).not_to include('<script>')
    end

    it 'handles tables with multiple rows and cells' do
      table.rows = [
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: 'A1'),
            Coradoc::CoreModel::TableCell.new(content: 'A2'),
            Coradoc::CoreModel::TableCell.new(content: 'A3')
          ]
        ),
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: 'B1'),
            Coradoc::CoreModel::TableCell.new(content: 'B2'),
            Coradoc::CoreModel::TableCell.new(content: 'B3')
          ]
        ),
        Coradoc::CoreModel::TableRow.new(
          cells: [
            Coradoc::CoreModel::TableCell.new(content: 'C1'),
            Coradoc::CoreModel::TableCell.new(content: 'C2'),
            Coradoc::CoreModel::TableCell.new(content: 'C3')
          ]
        )
      ]

      html = described_class.to_html(table)

      expect(html).to include('<td>A1</td>')
      expect(html).to include('<td>A2</td>')
      expect(html).to include('<td>A3</td>')
      expect(html).to include('<td>B1</td>')
      expect(html).to include('<td>B2</td>')
      expect(html).to include('<td>B3</td>')
      expect(html).to include('<td>C1</td>')
      expect(html).to include('<td>C2</td>')
      expect(html).to include('<td>C3</td>')
    end
  end

  describe '#to_coradoc' do
    it 'converts HTML table to CoreModel' do
      html = <<~HTML
        <table id="test-table">
          <caption>Test Caption</caption>
          <tr>
            <td>Cell 1</td>
            <td>Cell 2</td>
          </tr>
        </table>
      HTML

      nokogiri_doc = Nokogiri::HTML(html)
      table_element = nokogiri_doc.at_css('table')

      model = described_class.to_coradoc(table_element)

      expect(model).to be_a(Coradoc::CoreModel::Table)
      expect(model.id).to eq('test-table')
      expect(model.title).to eq('Test Caption')
      expect(model.rows.count).to eq(1)
    end
  end
end
