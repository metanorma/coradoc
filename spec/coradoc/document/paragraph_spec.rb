require "spec_helper"

RSpec.describe Coradoc::Document::Paragraph do
  describe ".initialize" do
    it "initilizes and exposes paragraph attributes" do
      contents = [Coradoc::Document::TextElement.new("Hi there")]

      paragraph = Coradoc::Document::Paragraph.new(contents)

      expect(paragraph.content).to eq(contents)
    end
  end
end
