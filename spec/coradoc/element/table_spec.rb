require "spec_helper"

RSpec.describe Coradoc::Element::Table do
  describe ".initialize" do
    it "initilizes and exposes attributes" do
      title = "Table"
      columns = [
        Coradoc::Element::TextElement.new(content: "hi"),
        Coradoc::Element::TextElement.new(content: "how"),
      ]

      row = Coradoc::Element::Table::Row.new(columns:)
      table = described_class.new(title:, rows: [row])

      expect(table.title).to eq(title)
      expect(table.rows.first).to eq(row)
      expect(table.rows.first.columns[0]).to eq(columns.first)
    end
  end
end
