require "spec_helper"

RSpec.describe Coradoc::Element::Title do
  describe ".initialization" do
    it "initializes instance and exposes attributes" do
      title = described_class.new(content: ast[:title],
                                  level: ast[:level_int],
                                  id: ast[:id],
                                  line_break: ast[:line_break])

      expect(title.id).to eq(ast[:id])
      expect(title.level_int).to eq(1)
      expect(title.content).to eq(ast[:title])
      expect(title.line_break).to eq(ast[:line_break])
    end
  end

  def ast
    @ast ||= {
      level_int: 1,
      id: "dummy-id",
      title: "Heading two",
      line_break: "\n\n",
    }
  end
end
