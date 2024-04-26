require "spec_helper"

RSpec.describe Coradoc::Element::Section do
  describe ".initialization" do
    it "initializes and exposes attributes" do
      id = "section_id"
      text = Coradoc::Element::TextElement.new("Text", line_break: "\n")
      title = Coradoc::Element::Title.new("Title", "==", line_break: "\n")

      section = Coradoc::Element::Section.new(title, id: id, contents: [text])

      expect(section.id).to eq(id)
      expect(section.title).to eq(title)
      expect(section.sections).to be_empty
      expect(section.contents.count).to eq(1)
      expect(section.contents.first).to eq(text)
    end
  end
end
