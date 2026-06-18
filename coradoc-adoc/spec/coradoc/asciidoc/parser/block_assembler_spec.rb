require "spec_helper"
require "coradoc/asciidoc/parser/block_assembler"

RSpec.describe Coradoc::AsciiDoc::Parser::BlockAssembler do
  describe ".assemble" do
    let(:input) do
      <<~ADOC
        ----
        code
        ----
      ADOC
    end

    it "returns nil when metadata is nil" do
      expect(described_class.assemble(input, nil)).to be_nil
    end

    it "includes only delimiter and lines when no title or attributes present" do
      metadata = {
        delimiter_line: 0,
        delimiter: { delimiter: "----" }
      }
      result = described_class.assemble(input, metadata)
      expect(result.keys).to contain_exactly(:delimiter, :lines)
      expect(result[:delimiter]).to eq("----")
    end

    it "includes title when metadata has :title" do
      metadata = {
        delimiter_line: 0,
        delimiter: { delimiter: "----" },
        title: { text: "My Code" }
      }
      result = described_class.assemble(input, metadata)
      expect(result[:title]).to eq("My Code")
    end

    it "includes attribute_list when metadata has :attributes" do
      metadata = {
        delimiter_line: 0,
        delimiter: { delimiter: "----" },
        attributes: { content: "[source,ruby]", attributes: ["source", "ruby"] }
      }
      result = described_class.assemble(input, metadata)
      expect(result[:attribute_list]).not_to be_nil
    end

    it "includes both title and attribute_list when both are present" do
      metadata = {
        delimiter_line: 0,
        delimiter: { delimiter: "----" },
        title: { text: "T" },
        attributes: { content: "[source]", attributes: ["source"] }
      }
      result = described_class.assemble(input, metadata)
      expect(result.keys).to contain_exactly(:delimiter, :lines, :title, :attribute_list)
    end
  end

  describe ".extract_block_lines" do
    it "handles plain text" do
      input = <<~ADOC
        --
        plain text
        --
      ADOC

      lines = input.lines
      result = described_class.extract_block_lines(lines, 0, "--")
      expect(result).to eq([
        { text: "plain text", line_break: "\n" }
      ])
    end

    it "handles nested code blocks" do
      input = <<~ADOC
        --
        [source,console]
        ----
        brew install metanorma
        ----
        --
      ADOC

      lines = input.lines
      result = described_class.extract_block_lines(lines, 0, "--")

      expect(result[0]).to eq({ text: "[source,console]", line_break: "\n" })
      expect(result[1][:block][:delimiter]).to eq("----")
      expect(result[1][:block][:lines]).to eq([{ text: "brew install metanorma", line_break: "\n" }])
    end
  end

  describe ".nested_delimiter?" do
    it "returns true for 4+ identical valid chars" do
      expect(described_class.nested_delimiter?("----")).to be true
      expect(described_class.nested_delimiter?("====")).to be true
      expect(described_class.nested_delimiter?("****")).to be true
    end

    it "returns true for exactly 2 dashes (open block)" do
      expect(described_class.nested_delimiter?("--")).to be true
    end

    it "returns false for 3 dashes (ambiguous)" do
      expect(described_class.nested_delimiter?("---")).to be false
    end

    it "returns false for 2 of any other valid char" do
      expect(described_class.nested_delimiter?("==")).to be false
      expect(described_class.nested_delimiter?("**")).to be false
    end

    it "returns false for non-delimiter characters" do
      expect(described_class.nested_delimiter?("xy")).to be false
      expect(described_class.nested_delimiter?("a")).to be false
      expect(described_class.nested_delimiter?("")).to be false
    end
  end
end
