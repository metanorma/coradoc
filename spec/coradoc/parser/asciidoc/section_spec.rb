require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::Section" do
  describe ".parse" do
    it "it parses section tile and body" do
      section = <<~TEXT
        == Section title
        Section content
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      paragraph = ast.first[:section][:contents][0][:paragraph]

      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(paragraph[:lines][0][:text]).to eq("Section content")
    end

    it "it parses section tile and body" do
      section = <<~TEXT
        == Section title
        [[inline_id]] Section content
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      paragraph = ast.first[:section][:contents][0][:paragraph]

      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(paragraph[:lines][0][:text]).to eq("Section content")
    end


    it "it parses section id, title and body" do
      
      section = <<~TEXT
        [[section_id]]
        == Section title
        Section content
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      paragraph = ast.first[:section][:contents][0][:paragraph]

      expect(ast.first[:section][:id]).to eq("section_id")
      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(paragraph[:lines][0][:text]).to eq("Section content")
    end


    it "it parses section id, title and body" do
      section = <<~TEXT
        [#section_id]
        == Section title
        Section content
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      paragraph = ast.first[:section][:contents][0][:paragraph]

      expect(ast.first[:section][:id]).to eq("section_id")
      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(paragraph[:lines][0][:text]).to eq("Section content")
    end

    it "it parses legacy section id" do
      section = <<~TEXT
        [[section_id]]
        == Section title

        This is the content section

        [[section_id_5.1]]
        === Sub section title
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      expect(ast.first[:section][:id]).to eq("section_id")
      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(ast.first[:section][:sections].first[:section][:id]).to eq("section_id_5.1")
    end

    it "it parses nested sub sections" do
      section = <<~TEXT
        == Section title

        Section Content

        === Level 2 clause heading

        ==== Level 3 clause heading

        ===== Level 4 clause heading

        ====== Level 5 clause heading

        ======= Level 6 clause heading

        ======== Level 7 clause heading

        == Another section title
      TEXT

      ast = Asciidoc::SectionTester.parse(section)

      expect(ast[0][:section][:title][:level]).to eq("==")
      expect(ast[1][:section][:title][:level]).to eq("==")

      expect(ast[0][:section][:title][:text]).to eq("Section title")
      expect(ast[1][:section][:title][:text]).to eq("Another section title")

      level_two = ast[0][:section][:sections].first[:section]
      expect(level_two[:title][:level]).to eq("===")
      expect(level_two[:title][:text]).to eq("Level 2 clause heading")

      level_three = level_two[:sections].first[:section]
      expect(level_three[:title][:level]).to eq("====")
      expect(level_three[:title][:text]).to eq("Level 3 clause heading")

      level_four = level_three[:sections].first[:section]
      expect(level_four[:title][:level]).to eq("=====")
      expect(level_four[:title][:text]).to eq("Level 4 clause heading")

      level_five = level_four[:sections].first[:section]
      expect(level_five[:title][:level]).to eq("======")
      expect(level_five[:title][:text]).to eq("Level 5 clause heading")

      level_six = level_five[:sections].first[:section]
      expect(level_six[:title][:level]).to eq("=======")
      expect(level_six[:title][:text]).to eq("Level 6 clause heading")

      level_seven = level_six[:sections].first[:section]
      expect(level_seven[:title][:level]).to eq("========")
      expect(level_seven[:title][:text]).to eq("Level 7 clause heading")
    end

    it "it parses section with inline id" do
      section = <<~TEXT
        [[section_id]]
        == Section title
        Section content

        [[inline_id]] This is inline id

        [[section_id_two]]
        === This is another section id
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      contents = ast.first[:section][:contents]

      expect(ast.first[:section][:id]).to eq("section_id")
      expect(ast.first[:section][:title][:level]).to eq("==")
      expect(ast.first[:section][:title][:text]).to eq("Section title")
      expect(contents[0][:paragraph][:lines][0][:text]).to eq("Section content")
      expect(contents[1][:paragraph][:lines][0][:id]).to eq("inline_id")
      expect(contents[1][:paragraph][:lines][0][:text]).to eq("This is inline id")

      sub_sections = ast.first[:section][:sections]
      expect(sub_sections[0][:section][:id]).to eq("section_id_two")
      expect(sub_sections[0][:section][:title][:text]).to eq("This is another section id")
    end

    it "it parses section with inline id" do
      section = <<~TEXT
        [[section_id]]
        == Section title

        * List item one
        * [[list_item_id]] List item two
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      section = ast[0][:section]
      list_items = section[:contents].first[:list][:unordered]

      expect(section[:id]).to eq("section_id")
      expect(section[:title][:text]).to eq("Section title")

      expect(list_items[0][:list_item][:text]).to eq("List item one")
      expect(list_items[1][:list_item][:id]).to eq("list_item_id")
      expect(list_items[1][:list_item][:text]).to eq("List item two")
    end

    it "parses blocks with different types" do
      section = <<~TEXT
        === Basic block with perimeters

        .Example block (open block syntax)
        [example]
        --
        This renders as an example.
        --

        .Example block (with block perimeter type)
        [example]
        ====
        This renders as an example.
        ====

        .Source block (with block perimeter type)
        ----
        Renders in monospace
        ----
      TEXT

      ast = Asciidoc::SectionTester.parse(section)
      section = ast.first[:section]
      contents = section[:contents]

      expect(contents.count).to eq(3)
      expect(contents[0][:block][:attribute_list][:attribute_array][0][:positional]).to eq("example")
      expect(contents[1][:block][:delimiter]).to eq("====")
      expect(section[:title][:text]).to eq("Basic block with perimeters")
      expect(contents[2][:block][:lines][0][:text]).to eq("Renders in monospace")
    end
  end

  module Asciidoc
    class SectionTester < Coradoc::Parser::Asciidoc::Base

      rule(:document) { (section | any.as(:unparsed)).repeat(1) }
      root :document

      def self.parse(text)
        new.parse_with_debug(text)
      end
    end
  end
end
