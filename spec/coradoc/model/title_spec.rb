# frozen_string_literal: true

RSpec.describe Coradoc::Model::Title do
  describe ".initialize" do
    it "initializes with all attributes" do
      title = described_class.new(
        id: "section-1",
        content: "Section Title",
        level_int: 2,
        style: "discrete",
        line_break: "\n\n",
      )

      expect(title.id).to eq("section-1")
      expect(title.content).to eq("Section Title")
      expect(title.level_int).to eq(2)
      expect(title.style).to eq("discrete")
      expect(title.line_break).to eq("\n\n")
    end

    it "uses default values" do
      title = described_class.new

      expect(title.id).to be_nil
      expect(title.content).to be_nil
      expect(title.level_int).to be_nil
      expect(title.style).to be_nil
      expect(title.line_break).to eq("\n")
    end
  end

  describe "#level_str" do
    it "generates correct level markers for levels 1-5" do
      (1..5).each do |level|
        title = described_class.new(level_int: level)
        expect(title.level_str).to eq("=" * (level + 1))
      end
    end

    it "uses maximum of 6 equals signs for levels > 5" do
      [6, 7, 8].each do |level|
        title = described_class.new(level_int: level)
        expect(title.level_str).to eq("======")
      end
    end
  end

  describe "#style_str" do
    it "returns nil when no style is set" do
      title = described_class.new
      expect(title.style_str).to be_nil
    end

    context "with no level_int" do
      it "returns nil" do
        title = described_class.new(style: "discrete")
        expect(title.style_str).to be_nil
      end
    end

    context "with level_int" do
      it "formats basic style" do
        title = described_class.new(level_int: 1, style: "discrete")
        expect(title.style_str).to eq("[discrete]\n")
      end

      it "includes level when > 5" do
        title = described_class.new(level_int: 6)
        expect(title.style_str).to eq("[level=6]\n")
      end

      it "combines style and level" do
        title = described_class.new(style: "discrete", level_int: 6)
        expect(title.style_str).to eq("[discrete,level=6]\n")
      end
    end
  end

  describe "#to_asciidoc" do
    before do
      allow(Coradoc::Generator).to receive(:gen_adoc) { |content| content }
      allow(Coradoc).to receive(:strip_unicode) { |content| content }
    end

    it "generates basic title" do
      title = described_class.new(content: "Section Title", level_int: 1)

      expect(title.to_asciidoc).to eq("\n== Section Title\n")
    end

    it "includes anchor when present" do
      title = described_class.new(content: "Section Title", level_int: 1)
      allow(title).to receive(:id).and_return("section-1")

      expect(title.to_asciidoc).to eq("\n[[section-1]]\n== Section Title\n")
    end

    it "includes style when present" do
      title = described_class.new(
        content: "Section Title",
        level_int: 1,
        style: "discrete",
      )

      expect(title.to_asciidoc).to eq("\n[discrete]\n== Section Title\n")
    end

    it "handles deep nesting levels" do
      title = described_class.new(content: "Deep Section", level_int: 6)

      expect(title.to_asciidoc).to eq("\n[level=6]\n====== Deep Section\n")
    end

    it "processes content through unicode stripping" do
      title = described_class.new(content: "Section Title", level_int: 1)

      expect(Coradoc).to receive(:strip_unicode).with("Section Title")
      title.to_asciidoc
    end
  end

  describe "inheritance and includes" do
    it "inherits from Base" do
      expect(described_class.superclass).to eq(Coradoc::Model::Base)
    end

    it "includes Anchorable module" do
      expect(described_class.included_modules).to include(Coradoc::Model::Anchorable)
    end
  end

  describe "aliases" do
    it "aliases content as text" do
      title = described_class.new(content: "Section Title")
      expect(title.text).to eq("Section Title")
    end
  end
end
