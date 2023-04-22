require "spec_helper"

RSpec.describe Coradoc::Document::Section do
  describe ".initialization" do
    it "initializes and exposes attributes" do
      text = Coradoc::Document::TextElement.new("Text", line_break: "\n")
      title = Coradoc::Document::Title.new("Title", "==", line_break: "\n")

      section = Coradoc::Document::Section.new(title, paragraphs: [text])

      expect(section.title).to eq(title)
      expect(section.blocks).to be_empty
      expect(section.paragraphs.count).to eq(1)
      expect(section.paragraphs.first).to eq(text)
    end
  end
end
