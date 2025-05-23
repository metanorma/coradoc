# frozen_string_literal: true

RSpec.describe Coradoc::Model::Inline::Monospace do
  describe ".initialize" do
    it "initializes with content" do
      mono = described_class.new(content: "code sample")

      expect(mono.content).to eq("code sample")
      expect(mono.unconstrained).to be true
    end

    it "accepts unconstrained parameter" do
      mono = described_class.new(
        content: "code sample",
        unconstrained: false
      )

      expect(mono.content).to eq("code sample")
      expect(mono.unconstrained).to be false
    end

    it "uses default values" do
      mono = described_class.new

      expect(mono.content).to be_nil
      expect(mono.unconstrained).to be true
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
    end

    context "with unconstrained true (default)" do
      it "uses double backticks" do
        mono = described_class.new(content: "code sample")
        expect(mono.to_asciidoc).to eq("``code sample``")
      end

      it "processes content through Generator" do
        mono = described_class.new(content: "code sample")
        expect(Coradoc::Generator).to receive(:gen_adoc).with("code sample")
        mono.to_asciidoc
      end
    end

    context "with unconstrained false" do
      it "uses single backticks" do
        mono = described_class.new(
          content: "code sample",
          unconstrained: false
        )
        expect(mono.to_asciidoc).to eq("`code sample`")
      end
    end

    it "handles multiline content" do
      mono = described_class.new(content: "line 1\nline 2")
      expect(mono.to_asciidoc).to eq("``line 1\nline 2``")
    end

    it "handles empty content" do
      mono = described_class.new(content: "")
      expect(mono.to_asciidoc).to eq("")
    end

    it "handles nil content" do
      mono = described_class.new
      allow(Coradoc::Generator).to receive(:gen_adoc).with(nil).and_return("")
      expect(mono.to_asciidoc).to eq("")
    end

    it "preserves special characters in content" do
      mono = described_class.new(content: "code ` with * and _ and #")
      expect(mono.to_asciidoc).to eq("``code \\` with * and _ and #``")
    end

    it "handles code with embedded backticks" do
      mono = described_class.new(content: "code with `backticks`")
      expect(mono.to_asciidoc).to eq("``code with \\`backticks```")
    end
  end

  describe "inheritance" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end
  end


end
