# frozen_string_literal: true

RSpec.describe Coradoc::Model::Block do
  describe Coradoc::Model::Block::Core do
    # ... existing Core tests ...
  end

  describe Coradoc::Model::Block::Quote do
    let(:title) { "Sample Quote" }
    let(:lines) { ["First line", "Second line"] }
    let(:attributes) { Coradoc::Model::AttributeList.new }

    describe ".initialize" do
      it "initializes with default delimiter settings" do
        quote = described_class.new

        expect(quote.delimiter_char).to eq("_")
        expect(quote.delimiter_len).to eq(4)
      end

      it "accepts custom attributes while maintaining defaults" do
        quote = described_class.new(
          title: title,
          lines: lines,
          attributes: attributes
        )

        expect(quote.title).to eq(title)
        expect(quote.lines).to eq(lines)
        expect(quote.attributes).to eq(attributes)
        expect(quote.delimiter_char).to eq("_")
        expect(quote.delimiter_len).to eq(4)
      end
    end

    describe "#to_asciidoc" do
      before do
        allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content.is_a?(Array) ? content.join("\n") : content }
      end

      it "generates complete quote block" do
        quote = described_class.new(
          title: title,
          lines: lines
        )

        expected_output = "\n\n.Sample Quote\n____\nFirst line\nSecond line\n____\n\n"
        expect(quote.to_asciidoc).to eq(expected_output)
      end

      it "generates quote block with attributes" do
        allow(attributes).to receive(:to_asciidoc)
          .with(false)
          .and_return('[source]')

        quote = described_class.new(
          title: title,
          lines: lines,
          attributes: attributes
        )

        expected_output = "\n\n.Sample Quote\n[source]\n____\nFirst line\nSecond line\n____\n\n"
        expect(quote.to_asciidoc).to eq(expected_output)
      end

      it "generates quote block without title" do
        quote = described_class.new(lines: lines)

        expected_output = "\n\n____\nFirst line\nSecond line\n____\n\n"
        expect(quote.to_asciidoc).to eq(expected_output)
      end

      it "generates empty quote block" do
        quote = described_class.new

        expected_output = "\n\n____\n\n____\n\n"
        expect(quote.to_asciidoc).to eq(expected_output)
      end
    end

    describe "inheritance" do
      it "inherits from Core" do
        expect(described_class.superclass).to eq(Coradoc::Model::Block::Core)
      end

      it "inherits Core's anchor functionality" do
        anchor = instance_double(Coradoc::Model::Inline::Anchor,
          to_asciidoc: "[[quote-1]]"
        )

        quote = described_class.new(lines: lines)
        allow(quote).to receive(:anchor).and_return(anchor)

        expected_output = "\n\n[[quote-1]]\n____\nFirst line\nSecond line\n____\n\n"
        expect(quote.to_asciidoc).to eq(expected_output)
      end
    end
  end
end
