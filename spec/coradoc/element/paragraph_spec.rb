require "spec_helper"

RSpec.describe Coradoc::Element::Paragraph do
  describe ".initialize" do
    it "initilizes and exposes paragraph attributes" do
      contents = [Coradoc::Element::TextElement.new(content: "Hi there")]

      paragraph = described_class.new(content: contents)

      expect(paragraph.content).to eq(contents)
    end
  end
end
