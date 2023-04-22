require "spec_helper"

RSpec.describe Coradoc::Document::TextElement do
  describe ".initialize" do
    it "initializes and exposes text element" do
      content = "This is text content"

      text = Coradoc::Document::TextElement.new(content, line_break: "\n")

      expect(text.content).to eq(content)
      expect(text.line_break).to eq("\n")
    end
  end
end
