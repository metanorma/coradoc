# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Transform::ElementTransformers::TableTransformer do
  describe '.transform_table' do
    it 'transforms a table with header row' do
      cell1 = Coradoc::AsciiDoc::Model::TableCell.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Header 1')]
      )
      row1 = Coradoc::AsciiDoc::Model::TableRow.new(
        columns: [cell1],
        header: true
      )
      title = Coradoc::AsciiDoc::Model::Title.new(content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Table 1')])
      table = Coradoc::AsciiDoc::Model::Table.new(
        id: 'tab-1',
        title: title,
        rows: [row1]
      )

      result = described_class.transform_table(table)

      expect(result).to be_a(Coradoc::CoreModel::Table)
      expect(result.id).to eq('tab-1')
      expect(result.title).to eq('Table 1')
      expect(result.rows.size).to eq(1)

      expect(result.rows[0]).to be_a(Coradoc::CoreModel::TableRow)
      expect(result.rows[0].header).to be true
      expect(result.rows[0].cells.size).to eq(1)

      expect(result.rows[0].cells[0]).to be_a(Coradoc::CoreModel::TableCell)
      expect(result.rows[0].cells[0].content).to eq('Header 1')
    end

    it 'transforms a table with merged cells' do
      cell = Coradoc::AsciiDoc::Model::TableCell.new(
        content: [Coradoc::AsciiDoc::Model::TextElement.new(content: 'Merged')],
        colspan: 2,
        rowspan: 3,
        halign: '^',
        valign: '^',
        style_name: 'strong'
      )
      row = Coradoc::AsciiDoc::Model::TableRow.new(
        columns: [cell],
        header: false
      )
      table = Coradoc::AsciiDoc::Model::Table.new(
        rows: [row]
      )

      result = described_class.transform_table(table)

      core_cell = result.rows[0].cells[0]
      expect(core_cell.content).to eq('Merged')
      expect(core_cell.colspan).to eq(2)
      expect(core_cell.rowspan).to eq(3)
      expect(core_cell.alignment).to eq('center')
      expect(core_cell.style).to eq(nil)
    end

    it 'transforms a table with inline elements in cells' do
      cell = Coradoc::AsciiDoc::Model::TableCell.new(
        content: [
          Coradoc::AsciiDoc::Model::TextElement.new(content: 'Hello '),
          Coradoc::AsciiDoc::Model::Inline::Bold.new(content: 'bold')
        ]
      )
      row = Coradoc::AsciiDoc::Model::TableRow.new(
        columns: [cell],
        header: false
      )
      table = Coradoc::AsciiDoc::Model::Table.new(
        rows: [row]
      )

      result = described_class.transform_table(table)

      core_cell = result.rows[0].cells[0]
      expect(core_cell.content).to match(/Hello\s+bold/)
      expect(core_cell.children.size).to eq(2)
      expect(core_cell.children[1]).to be_a(Coradoc::CoreModel::BoldElement)
      expect(core_cell.children[1].content).to eq('bold')
    end

    it 'transforms an empty table' do
      table = Coradoc::AsciiDoc::Model::Table.new(
        rows: []
      )

      result = described_class.transform_table(table)

      expect(result).to be_a(Coradoc::CoreModel::Table)
      expect(result.rows).to be_empty
    end
  end
end
