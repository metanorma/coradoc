require "spec_helper"

RSpec.describe Coradoc::Document::Title do
  describe ".initialization" do
    it "initializes instance and exposes attributes" do
      title = Coradoc::Document::Title.new(
        ast[:title],
        ast[:level],
        id: ast[:id],
        line_break: ast[:line_break],
      )

      expect(title.id).to eq(ast[:id])
      expect(title.level).to eq(:heading_two)
      expect(title.content).to eq(ast[:title])
      expect(title.line_break).to eq(ast[:line_break])
    end
  end

  def ast
    @ast ||= {
      level: "==",
      id: "dummy-id",
      title: "Heading two",
      line_break: "\n\n"
    }
  end
end
