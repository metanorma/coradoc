# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline do
  describe Coradoc::Model::Inline::Bold do
    let(:content) { "Sample text" }

    describe ".initialize" do
      it "initializes with content" do
        bold = described_class.new(content: content)

        expect(bold.content).to eq(content)
        expect(bold.unconstrained).to be true
      end

      it "uses default values when not provided" do
        bold = described_class.new

        expect(bold.content).to be_nil
        expect(bold.unconstrained).to be true
      end

      it "accepts unconstrained parameter" do
        bold = described_class.new(content: content, unconstrained: false)

        expect(bold.content).to eq(content)
        expect(bold.unconstrained).to be false
      end
    end

    describe "#to_asciidoc" do
      before do
        allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
      end

      context "when unconstrained is true" do
        it "uses double asterisks" do
          bold = described_class.new(content: content)
          expect(bold.to_asciidoc).to eq("**Sample text**")
        end
      end

      context "when unconstrained is false" do
        it "uses single asterisks" do
          bold = described_class.new(content: content, unconstrained: false)
          expect(bold.to_asciidoc).to eq("*Sample text*")
        end
      end

      it "processes content through Generator.gen_adoc" do
        bold = described_class.new(content: content)
        expect(Coradoc::Generator).to receive(:gen_adoc).with(content)
        bold.to_asciidoc
      end
    end
  end

  describe Coradoc::Model::Inline::Italic do
    let(:content) { "Sample text" }

    describe ".initialize" do
      it "initializes with content" do
        italic = described_class.new(content: content)

        expect(italic.content).to eq(content)
        expect(italic.unconstrained).to be true
      end

      it "uses default values when not provided" do
        italic = described_class.new

        expect(italic.content).to be_nil
        expect(italic.unconstrained).to be true
      end

      it "accepts unconstrained parameter" do
        italic = described_class.new(content: content, unconstrained: false)

        expect(italic.content).to eq(content)
        expect(italic.unconstrained).to be false
      end
    end

    describe "#to_asciidoc" do
      before do
        allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
      end

      context "when unconstrained is true" do
        it "uses double underscores" do
          italic = described_class.new(content: content)
          expect(italic.to_asciidoc).to eq("__Sample text__")
        end
      end

      context "when unconstrained is false" do
        it "uses single underscores" do
          italic = described_class.new(content: content, unconstrained: false)
          expect(italic.to_asciidoc).to eq("_Sample text_")
        end
      end

      it "processes content through Generator.gen_adoc" do
        italic = described_class.new(content: content)
        expect(Coradoc::Generator).to receive(:gen_adoc).with(content)
        italic.to_asciidoc
      end

      it "handles nil content" do
        italic = described_class.new
        allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
        expect(italic.to_asciidoc).to eq("")
      end

      it "handles empty content" do
        italic = described_class.new(content: "")
        expect(italic.to_asciidoc).to eq("")
      end
    end
  end
end
