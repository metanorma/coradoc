# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/drop/table_drop'
require 'coradoc/html/drop/table_row_drop'
require 'coradoc/html/drop/table_cell_drop'

RSpec.describe Coradoc::Html::Drop::TableDrop do
  let(:model) { CoreModel::Table.new(id: 't1', title: 'My Table') }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#id' do
    it 'returns the model id' do
      expect(drop.id).to eq('t1')
    end
  end

  describe '#title' do
    it 'returns escaped title' do
      expect(drop.title).to eq('My Table')
    end
  end

  describe '#rows' do
    it 'returns an array of TableRowDrop' do
      row = CoreModel::TableRow.new
      table = CoreModel::Table.new(rows: [row])
      rows = described_class.new(table).rows
      expect(rows).to be_an(Array)
      expect(rows.first).to be_a(Coradoc::Html::Drop::TableRowDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::TableRowDrop do
  let(:model) { CoreModel::TableRow.new }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#header?' do
    it 'returns true for header row' do
      row = CoreModel::TableRow.new(header: true)
      expect(described_class.new(row).header?).to be true
    end

    it 'returns false for non-header row' do
      expect(drop.header?).to be false
    end
  end

  describe '#html_tag' do
    it 'returns tr for header row' do
      row = CoreModel::TableRow.new(header: true)
      expect(described_class.new(row).html_tag).to eq('tr')
    end

    it 'returns tr for non-header row' do
      expect(drop.html_tag).to eq('tr')
    end
  end

  describe '#cells' do
    it 'returns an array of TableCellDrop' do
      cell = CoreModel::TableCell.new
      row = CoreModel::TableRow.new(cells: [cell])
      cells = described_class.new(row).cells
      expect(cells).to be_an(Array)
      expect(cells.first).to be_a(Coradoc::Html::Drop::TableCellDrop)
    end
  end
end

RSpec.describe Coradoc::Html::Drop::TableCellDrop do
  let(:model) { CoreModel::TableCell.new }
  let(:drop) { described_class.new(model) }

  it_behaves_like 'a liquid drop'

  describe '#header?' do
    it 'returns true for header cell' do
      cell = CoreModel::TableCell.new(header: true)
      expect(described_class.new(cell).header?).to be true
    end

    it 'returns false for data cell' do
      expect(drop.header?).to be false
    end
  end

  describe '#html_tag' do
    it 'returns th for header cell' do
      cell = CoreModel::TableCell.new(header: true)
      expect(described_class.new(cell).html_tag).to eq('th')
    end

    it 'returns td for data cell' do
      expect(drop.html_tag).to eq('td')
    end
  end

  describe '#colspan' do
    it 'returns colspan as string' do
      cell = CoreModel::TableCell.new(colspan: 2)
      expect(described_class.new(cell).colspan).to eq('2')
    end
  end

  describe '#rowspan' do
    it 'returns rowspan as string' do
      cell = CoreModel::TableCell.new(rowspan: 3)
      expect(described_class.new(cell).rowspan).to eq('3')
    end
  end

  describe '#style' do
    it 'returns text-align style for alignment' do
      cell = CoreModel::TableCell.new(alignment: 'center')
      expect(described_class.new(cell).style).to eq('text-align: center')
    end

    it 'returns nil without alignment' do
      expect(drop.style).to be_nil
    end
  end
end
