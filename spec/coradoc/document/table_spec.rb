require "spec_helper"

RSpec.describe Coradoc::Document::Table do
  describe ".initialize" do
    it "initilizes and exposes attributes" do
      title = "Table"
      columns = [
        Coradoc::Document::TextElement.new("hi"),
        Coradoc::Document::TextElement.new("how"),
      ]

      row = Coradoc::Document::Table::Row.new(columns)
      table = Coradoc::Document::Table.new(title, [row])

      expect(table.title).to eq(title)
      expect(table.rows.first).to eq(row)
      expect(table.rows.first.columns[0]).to eq(columns.first)
    end
  end
end
