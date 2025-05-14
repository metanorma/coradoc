require "spec_helper"

RSpec.describe Coradoc::Element::Admonition do
  describe ".initialize" do
    it "initializes and exposes admonition attributes" do
      type = "NOTE"
      text = "This is note type admonition"

      admonition = described_class.new(content: text,
                                       type:,
                                       line_break: "\n")

      expect(admonition.content).to eq(text)
      expect(admonition.line_break).to eq("\n")
      expect(admonition.type).to eq(type.downcase.to_sym)
    end
  end
end
