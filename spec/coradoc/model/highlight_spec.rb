# frozen_string_literal: true

RSpec.describe Coradoc::Model::Highlight do
  describe "inheritance" do
    it "inherits from TextElement" do
      expect(described_class.superclass).to eq(Coradoc::Model::TextElement)
    end
  end

  describe "functionality" do
    let(:content) { "Sample highlighted text" }

    it "inherits TextElement initialization" do
      highlight = described_class.new(content: content)
      expect(highlight.content).to eq(content)
    end

    it "inherits TextElement#to_asciidoc" do
      highlight = described_class.new(content: content)
      allow(Coradoc::Generator).to receive(:gen_adoc).with(content).and_return(content)

      expect(highlight.to_asciidoc).to eq(content)
    end

    it "inherits default values from TextElement" do
      highlight = described_class.new

      expect(highlight.content).to eq("")
      expect(highlight.line_break).to eq("")
      expect(highlight.id).to be_nil
    end

    it "inherits line_break functionality from TextElement" do
      highlight = described_class.new(content: content, line_break: "\n")
      allow(Coradoc::Generator).to receive(:gen_adoc).with(content).and_return(content)

      expect(highlight.to_asciidoc).to eq("#{content}\n")
    end
  end
end
