# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Table do
  describe '#initialize' do
    it 'creates table with id' do
      table = described_class.new(id: 'my-table')

      expect(table.id).to eq('my-table')
    end

    it 'creates table with title' do
      table = described_class.new(title: 'My Table')

      expect(table.title).to eq('My Table')
    end

    it 'creates table with rows' do
      cell = Coradoc::AsciiDoc::Model::TableCell.new(content: [])
      row = Coradoc::AsciiDoc::Model::TableRow.new(columns: [cell])
      table = described_class.new(rows: [row])

      expect(table.rows).to eq([row])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::TableRow do
  describe '#initialize' do
    it 'creates row with columns' do
      cell = Coradoc::AsciiDoc::Model::TableCell.new(content: [])
      row = described_class.new(columns: [cell])

      expect(row.columns).to eq([cell])
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::TableCell do
  describe '#initialize' do
    it 'creates cell with content' do
      text = Coradoc::AsciiDoc::Model::TextElement.new(content: 'Cell content')
      cell = described_class.new(content: [text])

      expect(cell.content).to eq([text])
    end

    it 'creates cell with alignattr' do
      cell = described_class.new(content: [], alignattr: '>')

      expect(cell.alignattr).to eq('>')
    end

    it 'creates cell with colrowattr' do
      cell = described_class.new(content: [], colrowattr: '2.1')

      expect(cell.colrowattr).to eq('2.1')
    end

    it 'creates cell with style' do
      cell = described_class.new(content: [], style: 'a')

      expect(cell.style).to eq('a')
    end
  end

  describe '#asciidoc?' do
    it "returns true when style includes 'a'" do
      cell = described_class.new(content: [], style: 'a')

      expect(cell.asciidoc?).to be true
    end

    it "returns false when style does not include 'a'" do
      cell = described_class.new(content: [], style: 'h')

      expect(cell.asciidoc?).to be false
    end
  end
end
