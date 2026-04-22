# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::CoreModel::Table do
  describe '.new' do
    let(:header_cell) { Coradoc::CoreModel::TableCell.new(content: 'Name', header: true) }
    let(:data_cell) { Coradoc::CoreModel::TableCell.new(content: 'Value') }
    let(:header_row) { Coradoc::CoreModel::TableRow.new(cells: [header_cell, header_cell], header: true) }
    let(:data_row) { Coradoc::CoreModel::TableRow.new(cells: [data_cell, data_cell]) }

    it 'creates a table with rows' do
      table = described_class.new(
        title: 'Data Table',
        rows: [header_row, data_row]
      )

      expect(table.title).to eq('Data Table')
      expect(table.rows).to be_an(Array)
      expect(table.rows.count).to eq(2)
    end

    it 'creates a table with formatting options' do
      table = described_class.new(
        frame: 'all',
        grid: 'all',
        width: '100%'
      )

      expect(table.frame).to eq('all')
      expect(table.grid).to eq('all')
      expect(table.width).to eq('100%')
    end
  end

  describe '#semantically_equivalent?' do
    let(:cell1) { Coradoc::CoreModel::TableCell.new(content: 'A') }
    let(:cell2) { Coradoc::CoreModel::TableCell.new(content: 'B') }
    let(:row1) { Coradoc::CoreModel::TableRow.new(cells: [cell1]) }
    let(:row2) { Coradoc::CoreModel::TableRow.new(cells: [cell2]) }

    let(:table1) { described_class.new(rows: [row1]) }
    let(:table2) { described_class.new(rows: [row1]) }
    let(:table3) { described_class.new(rows: [row2]) }

    it 'returns true for identical tables' do
      expect(table1.semantically_equivalent?(table2)).to be true
    end

    it 'returns false for tables with different rows' do
      expect(table1.semantically_equivalent?(table3)).to be false
    end
  end

  describe 'inheritance' do
    it 'inherits from CoreModel::Base' do
      expect(described_class.superclass).to eq(Coradoc::CoreModel::Base)
    end
  end
end

RSpec.describe Coradoc::CoreModel::TableRow do
  describe '.new' do
    it 'creates a row with cells' do
      cell1 = Coradoc::CoreModel::TableCell.new(content: 'Cell 1')
      cell2 = Coradoc::CoreModel::TableCell.new(content: 'Cell 2')
      row = described_class.new(cells: [cell1, cell2])

      expect(row.cells).to be_an(Array)
      expect(row.cells.count).to eq(2)
    end

    it 'creates a header row' do
      row = described_class.new(cells: [], header: true)

      expect(row.header).to be true
    end
  end
end

RSpec.describe Coradoc::CoreModel::TableCell do
  describe '.new' do
    it 'creates a cell with content' do
      cell = described_class.new(content: 'Cell content')

      expect(cell.content).to eq('Cell content')
    end

    it 'creates a cell with formatting options' do
      cell = described_class.new(
        content: 'Spanning cell',
        alignment: 'center',
        colspan: 2,
        rowspan: 1,
        header: true
      )

      expect(cell.alignment).to eq('center')
      expect(cell.colspan).to eq(2)
      expect(cell.rowspan).to eq(1)
      expect(cell.header).to be true
    end
  end
end
