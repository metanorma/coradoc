# frozen_string_literal: true

require 'spec_helper'
require 'coradoc/html/renderer'

RSpec.describe Coradoc::Html::Renderer, 'table rendering' do
  let(:renderer) { described_class.new }

  it 'renders table with header row using <thead>' do
    header_cell = CoreModel::TableCell.new(content: 'Header', header: true)
    header_row = CoreModel::TableRow.new(cells: [header_cell], header: true)
    body_cell = CoreModel::TableCell.new(content: 'Data')
    body_row = CoreModel::TableRow.new(cells: [body_cell])
    table = CoreModel::Table.new(rows: [header_row, body_row])
    html = renderer.render(table)
    expect(html).to include('<thead>')
    expect(html).to include('<th>')
    expect(html).to include('Header')
    expect(html).to include('Data')
  end

  it 'renders table without header as all <tr>' do
    cell = CoreModel::TableCell.new(content: 'Cell')
    row = CoreModel::TableRow.new(cells: [cell])
    table = CoreModel::Table.new(rows: [row])
    html = renderer.render(table)
    expect(html).not_to include('<thead>')
    expect(html).to include('<tr>')
    expect(html).to include('Cell')
  end

  it 'includes colspan and rowspan' do
    cell = CoreModel::TableCell.new(content: 'Wide', colspan: 2, rowspan: 3)
    row = CoreModel::TableRow.new(cells: [cell])
    table = CoreModel::Table.new(rows: [row])
    html = renderer.render(table)
    expect(html).to include('colspan="2"')
    expect(html).to include('rowspan="3"')
  end

  it 'includes table id and title' do
    cell = CoreModel::TableCell.new(content: 'Data')
    row = CoreModel::TableRow.new(cells: [cell])
    table = CoreModel::Table.new(id: 't1', title: 'Results', rows: [row])
    html = renderer.render(table)
    expect(html).to include('id="t1"')
    expect(html).to include('title="Results"')
  end
end
