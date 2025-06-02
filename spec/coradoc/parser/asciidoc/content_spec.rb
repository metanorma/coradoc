require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::Content" do
  describe ".parse" do
    it "parses content section with texts" do
      content = <<~TEXT
        This is are the sample text for content
        It can be distrubuted in multiple lines
      TEXT

      ast = Asciidoc::ContentTester.parse(content)
      # puts content
      # pp ast
      lines = ast.first[:paragraph][:lines]

      expect(lines[0][:text]).to eq("This is are the sample text for content")
      expect(lines[1][:text]).to eq("It can be distrubuted in multiple lines")
    end

    context "block types" do
      it "parses block with open type" do
        content = <<~TEXT
          .Side blocks (open block syntax)

          [sidebar]
          ****
          This renders in the side.
          ****
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block = ast.first[:block]

        expect(block[:attribute_list][:attribute_array][0][:positional]).to eq("sidebar")
        expect(block[:delimiter]).to eq("****")
        expect(block[:title]).to eq("Side blocks (open block syntax)")
        expect(block[:lines].first[:text]).to eq("This renders in the side.")
      end

      it "parses block only enforcing minimum permiter" do
        content = <<~TEXT
          .Side blocks (open block syntax)

          [sidebar]
          *****
          This renders in the side.
          *****
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block = ast.first[:block]

        expect(block[:attribute_list][:attribute_array][0][:positional]).to eq("sidebar")
        expect(block[:delimiter]).to eq("*****")
        expect(block[:title]).to eq("Side blocks (open block syntax)")
        expect(block[:lines].first[:text]).to eq("This renders in the side.")
      end

      it "parses blocks with perimeter" do
        content = <<~TEXT
          .Side blocks (with block perimeter type)

          ****
          This renders in the side.
          ****
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block = ast.first[:block]

        expect(block[:delimiter]).to eq("****")
        expect(block[:lines].first[:text]).to eq("This renders in the side.")
        expect(block[:title]).to eq("Side blocks (with block perimeter type)")
      end

      it "parses example type block" do
        content = <<~TEXT
          [example]
          ====
          Example text with open type
          ====

          ======
          Example text with permiter
          ======
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block_one = ast.first[:block]
        block_two = ast.last[:block]

        expect(block_one[:attribute_list][:attribute_array][0][:positional]).to eq("example")
        expect(block_one[:delimiter]).to eq("====")
        expect(block_two[:delimiter]).to eq("======")
        expect(block_two[:lines][0][:text]).to eq("Example text with permiter")
        expect(block_one[:lines][0][:text]).to eq("Example text with open type")
      end

      it "parses source type block" do
        content = <<~TEXT
          .Source block (open block syntax)
          [source]
          --
          This renders in monospace.
          --

          .Source block (with block perimeter type)
          ----
          This renders in monospace.
          ----
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block_one = ast.first[:block]
        block_two = ast.last[:block]

        expect(block_one[:attribute_list][:attribute_array][0][:positional]).to eq("source")
        expect(block_one[:delimiter]).to eq("--")
        expect(block_two[:delimiter]).to eq("----")
        expect(block_one[:lines][0][:text]).to eq("This renders in monospace.")
        expect(block_two[:lines][0][:text]).to eq("This renders in monospace.")
      end

      it "parses source type block" do
        content = <<~TEXT
          .Source block (open block syntax)
          [source]
          --
          This renders in monospace.
          --

          .Source block (with block perimeter type)
          ----
          This renders in monospace.
          ----
        TEXT

        ast = Asciidoc::ContentTester.parse(content)

        obj = [{ block: { title: "Source block (open block syntax)",
                          attribute_list: { attribute_array: [{ positional: "source" }] },
                          delimiter: "--",
                          lines: [{ text: "This renders in monospace.",
                                    line_break: "\n" }] } },
               { block: { title: "Source block (with block perimeter type)",
                          delimiter: "----",
                          lines: [{ text: "This renders in monospace.",
                                    line_break: "\n" }] } }]
        expect(ast).to eq(obj)
      end

      it "parses quote type block" do
        content = <<~TEXT
          .Quote block (open block syntax)
          [quote]
          --
          This is quote type text
          --

          .Quote block (with block perimeter)
          ____
          This is quote type text
          ____
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        block_one = ast.first[:block]
        block_two = ast.last[:block]

        expect(block_one[:attribute_list][:attribute_array][0][:positional]).to eq("quote")
        expect(block_one[:delimiter]).to eq("--")
        expect(block_two[:delimiter]).to eq("____")
        expect(block_one[:lines][0][:text]).to eq("This is quote type text")
      end
    end

    it "parses content with inline id" do
      content = <<~TEXT
        [[id_1.1_part_1]] This is the content with id
        This is content without any id

        [[guidance_5.1_part_1]] At highest level organization

        [[guidance_5.1_part_2]] The information security policy
      TEXT

      ast = Asciidoc::ContentTester.parse(content)
      paragraph_one = ast[0][:paragraph][:lines]
      paragraph_two = ast[1][:paragraph][:lines]
      paragraph_three = ast[2][:paragraph][:lines]

      expect(paragraph_one[0][:id]).to eq("id_1.1_part_1")
      expect(paragraph_one[0][:text]).to eq("This is the content with id")
      expect(paragraph_one[1][:text]).to eq("This is content without any id")

      expect(paragraph_two[0][:id]).to eq("guidance_5.1_part_1")
      expect(paragraph_two[0][:text]).to eq("At highest level organization")
      expect(paragraph_three[0][:id]).to eq("guidance_5.1_part_2")
    end

    context "paragraph" do
      it "parses paragraph with id" do
        content = <<~TEXT
          [id=myblock]
          This is my block with a defined ID.
          this is going to be the next line
        TEXT

        ast = Asciidoc::ContentTester.parse(content)
        paragraph = ast[0][:paragraph]

        expect(paragraph[:attribute_list][:attribute_array][0][:named][:named_key]).to eq("id")
        expect(paragraph[:attribute_list][:attribute_array][0][:named][:named_value]).to eq("myblock")
        expect(paragraph[:lines][0][:text]).to eq("This is my block with a defined ID.")
      end
    end

    context "paragraph" do
      it "parses paragraph with id 2" do
        content = <<~TEXT
          [id=myblock]
          This is my block with a defined ID.
          this is going to be the next line
        TEXT
        ast = Asciidoc::ContentTester.parse(content)
        obj = [{ paragraph: { attribute_list: { attribute_array: [{ named: { named_key: "id",
                                                                             named_value: "myblock" } }] },
                              lines: [{ text: "This is my block with a defined ID.", line_break: "\n" },
                                      { text: "this is going to be the next line",
                                        line_break: "\n" }] } }]
        expect(ast).to eq(obj)
      end
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

    it "parses the table block 2" do
      content = <<~DOC
        .Person table
        |===
        | *first_name* | last_name | email
        | John | Doe | john.doe@example.com
        | | doe | jennie.doe@example.com
        |===
      DOC

      ast = Asciidoc::ContentTester.parse(content)
      ast.first[:table]

      obj = { table: { title: "Person table",
                       rows: [{ cols: [{ text: "*first_name*" }, { text: "last_name" }, { text: "email" }] },
                              { cols: [{ text: "John" }, { text: "Doe" },
                                       { text: "john.doe@example.com" }] },
                              { cols: [{ text: " " }, { text: "doe" },
                                       { text: "jennie.doe@example.com" }] }] } }

      expect(ast.first).to eq(obj)
    end

    it "parses highlighted text block" do
      content = <<~DOC
        [[scls_5-9]]
        [underline]#Ownership#

        This is a pragraph block
      DOC

      ast = Asciidoc::ContentTester.parse(content)
      obj = [{ paragraph: { id: "scls_5-9",
                            lines: [{ text: [{ span_constrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                                                   text: "Ownership" } }],
                                      line_break: "\n" }] } },
             { paragraph: { lines: [{ text: "This is a pragraph block",
                                      line_break: "\n" }] } }]
      expect(ast).to eq(obj)
      # expect(ast[0][:highlight][:id]).to eq("scls_5-9")
      # expect(ast[0][:highlight][:text]).to eq("Ownership")
      # expect(ast[1][:paragraph][:lines][0][:text]).to eq("This is a pragraph block")
    end

    it "parses highlighted text block" do
      content = <<~DOC
        [[scls_5-9]]
        #Ownership#

        This is a pragraph block
      DOC

      ast = Asciidoc::ContentTester.parse(content)
      obj = [{ paragraph: { id: "scls_5-9",
                            lines: [{ text: [{ highlight_constrained: [{ text: "Ownership" }] }],
                                      line_break: "\n" }] } },
             { paragraph: { lines: [{ text: "This is a pragraph block",
                                      line_break: "\n" }] } }]
      expect(ast).to eq(obj)
      # expect(ast[0][:highlight][:id]).to eq("scls_5-9")
      # expect(ast[0][:highlight][:text]).to eq("Ownership")
      # expect(ast[1][:paragraph][:lines][0][:text]).to eq("This is a pragraph block")
    end
  end
end

module Asciidoc
  class ContentTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) do
      (contents | any.as(:unparsed)).repeat(1)
    end
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
