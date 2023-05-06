require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::Content" do
  describe ".parse" do
    it "parses content section with texts" do
      content = <<~TEXT
      This is are the sample text for content
      It can be distrubuted in multiple lines
      TEXT

      ast = Asciidoc::ContentTester.parse(content)
      lines = ast.first[:paragraph]

      expect(lines[0][:text]).to eq("This is are the sample text for content")
      expect(lines[1][:text]).to eq("It can be distrubuted in multiple lines")
    end

    it "parses content with glossaries" do
      content = <<~TEXT
      Clause:: 5.1
      Maps_27002_2013:: iso:5.1.1, iso:5.1.2

      This content block also contains some text
      TEXT

      ast = Asciidoc::ContentTester.parse(content)
      glossaries = ast.first[:glossaries]
      lines = ast[2][:paragraph]

      expect(glossaries[0][:key]).to eq("Clause")
      expect(glossaries[0][:value]).to eq("5.1")

      expect(glossaries[1][:key]).to eq("Maps_27002_2013")
      expect(glossaries[1][:value]).to eq("iso:5.1.1, iso:5.1.2")

      expect(lines[0][:text]).to eq("This content block also contains some text")
    end

    it "parses content with inline id" do
      content = <<~TEXT
      [[id_1.1_part_1]] This is the content with id
      This is content without any id

      [[guidance_5.1_part_1]] At highest level organization

      [[guidance_5.1_part_2]] The information security policy
      TEXT

      ast = Asciidoc::ContentTester.parse(content)
      paragraph_one = ast[0][:paragraph]
      paragraph_two = ast[2][:paragraph]
      paragraph_three = ast[4][:paragraph]

      expect(paragraph_one[0][:id]).to eq("id_1.1_part_1")
      expect(paragraph_one[0][:text]).to eq("This is the content with id")
      expect(paragraph_one[1][:text]).to eq("This is content without any id")

      expect(paragraph_two[0][:id]).to eq("guidance_5.1_part_1")
      expect(paragraph_three[0][:id]).to eq("guidance_5.1_part_2")
      expect(paragraph_two[0][:text]).to eq("At highest level organization")
    end

    it "parses list embeded in the content" do
      content = <<~DOC
        * Unnumbered list item 1
        * Unnumbered list item 2
        * [[list_item_id]] Unnumbered list item 3
      DOC

      ast = Asciidoc::ContentTester.parse(content)
      list_items = ast[0][:list][:unnumbered]

      expect(list_items.count).to eq(3)
      expect(list_items[0][:text]).to eq("Unnumbered list item 1")
      expect(list_items[2][:id]).to eq("list_item_id")
      expect(list_items[2][:text]).to eq("Unnumbered list item 3")
    end

    it "parses the table block" do
      content = <<~DOC
        .Person table
        |===
        | *first_name* | last_name | email
        | John | Doe | john.doe@example.com
        | | doe | jennie.doe@example.com
        |===
      DOC

      ast = Asciidoc::ContentTester.parse(content)
      table = ast.first[:table]

      expect(table[:rows].count).to eq(3)
      expect(table[:title]).to eq("Person table")
      expect(table[:rows][2][:cols][0][:text]).to eq(" ")
      expect(table[:rows][0][:cols][0][:text]).to eq("*first_name*")
      expect(table[:rows][1][:cols][2][:text]).to eq("john.doe@example.com")
    end

    it "parses highlighted text block" do
      content = <<~DOC
        [[scls_5-9]]
        [underline]#Ownership#

        This is a pragraph block
      DOC

      ast = Asciidoc::ContentTester.parse(content)

      expect(ast[0][:highlight][:id]).to eq("scls_5-9")
      expect(ast[0][:highlight][:text]).to eq("Ownership")
      expect(ast[1][:paragraph][0][:text]).to eq("This is a pragraph block")
    end
  end

  module Asciidoc
    class ContentTester < Parslet::Parser
      include Coradoc::Asciidoc::Content

      rule(:document) { (contents | any.as(:unparsed)).repeat(1) }
      root :document

      def self.parse(text)
        new.parse_with_debug(text)
      end
    end
  end
end

