# frozen_string_literal: true

RSpec.describe Coradoc::Model::Break do
  describe Coradoc::Model::Break::ThematicBreak do
    describe "#to_asciidoc" do
      it "generates thematic break markup" do
        break_element = described_class.new
        expect(break_element.to_asciidoc).to eq("\n* * *\n")
      end

      it "is consistent across multiple instances" do
        break1 = described_class.new
        break2 = described_class.new

        expect(break1.to_asciidoc).to eq(break2.to_asciidoc)
      end
    end
  end
end
