require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::List" do
  describe ".parse" do
    it "parses ordered list" do
      content = <<~DOC
        . Ordered list item 1
        . Ordered list item 2
        . [[list_item_id]] Ordered list item 3
      DOC

      ast = Asciidoc::ListTester.parse(content)
      list_items = ast[:list][:ordered]

      expect(list_items.count).to eq(3)
      expect(list_items[0][:list_item][:text]).to eq("Ordered list item 1")
      expect(list_items[2][:list_item][:id]).to eq("list_item_id")
      expect(list_items[2][:list_item][:text]).to eq("Ordered list item 3")
    end

    it "parser ordered list with empty lines between items" do
      content = <<~DOC
        . Ordered list item 1

        . Ordered list item 2
      DOC

      ast = Asciidoc::ListTester.parse(content)
      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "Ordered list item 1",
                                               line_break: "\n\n",
                                               attached: [],
                                               nested: [] } },
                                { list_item: { marker: ".",
                                               text: "Ordered list item 2",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [] } }] } }
      expect(ast).to eq(obj)
    end

    it "parses unordered list" do
      content = <<~DOC
        * Unordered list item 1
        * Unordered list item 2
        * [[list_item_id]] Unordered list item 3
      DOC

      ast = Asciidoc::ListTester.parse(content)
      list_items = ast[:list][:unordered]

      expect(list_items.count).to eq(3)
      expect(list_items[0][:list_item][:text]).to eq("Unordered list item 1")
      expect(list_items[2][:list_item][:id]).to eq("list_item_id")
      expect(list_items[2][:list_item][:text]).to eq("Unordered list item 3")

      obj = { list: { unordered: [{ list_item: { marker: "*",
                                                 text: "Unordered list item 1",
                                                 line_break: "\n",
                                                 attached: [],
                                                 nested: [] } },
                                  { list_item: { marker: "*",
                                                 text: "Unordered list item 2",
                                                 line_break: "\n",
                                                 attached: [],
                                                 nested: [] } },
                                  { list_item: { marker: "*",
                                                 id: "list_item_id",
                                                 text: "Unordered list item 3",
                                                 line_break: "\n",
                                                 attached: [],
                                                 nested: [] } }] } }

      expect(ast).to eq(obj)
    end

    it "parses ordered list with nesting" do
      content = <<~DOC
        . Ordered list item 1
        . Ordered list item 2
        .. Nested list item A
      DOC

      ast = Asciidoc::ListTester.parse(content)
      list_items = ast[:list][:ordered]

      expect(list_items.count).to eq(2)
      expect(list_items[1][:list_item][:nested][0][:list][:ordered][0][:list_item][:text]).to eq("Nested list item A")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "Ordered list item 1",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [] } },
                                { list_item: { marker: ".",
                                               text: "Ordered list item 2",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [{ list: { ordered: [{ list_item: { marker: "..",
                                                                                           text: "Nested list item A",
                                                                                           line_break: "\n",
                                                                                           attached: [],
                                                                                           nested: [] } }] } }] } }] } }

      expect(ast).to eq(obj)
    end

    it "parses list with attached paragraph" do
      content = <<~TEXT
        . This is a list item
        +
        With attached paragraph.
      TEXT

      ast = Asciidoc::ListTester.parse(content)
      items = ast[:list][:ordered]
      expect(items[0][:list_item][:text]).to eq("This is a list item")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "This is a list item",
                                               line_break: "\n",
                                               attached: [{ paragraph: { lines: [{ text: "With attached paragraph.",
                                                                                   line_break: "\n" }] } }],
                                               nested: [] } }] } }
      expect(ast).to eq(obj)
    end

    it "parses list with attached admonition" do
      content = <<~TEXT
        . This is a list item
        +
        NOTE: attached admonition.
      TEXT

      ast = Asciidoc::ListTester.parse(content)
      first_item = ast[:list][:ordered][0][:list_item]
      expect(first_item[:text]).to eq("This is a list item")
      expect(first_item[:attached][0][:admonition_type]).to eq("NOTE")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "This is a list item",
                                               line_break: "\n",
                                               attached: [{ admonition_type: "NOTE",
                                                            content: [{ text: "attached admonition.",
                                                                        line_break: "\n" }] }],
                                               nested: [] } }] } }
      expect(ast).to eq(obj)
    end

    it "parses list with attached paragraphs" do
      content = <<~TEXT
        . This is a list item
        +
        With attached paragraph.
        +
        And another attached paragraph.
      TEXT

      ast = Asciidoc::ListTester.parse(content)
      items = ast[:list][:ordered]
      expect(items[0][:list_item][:text]).to eq("This is a list item")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "This is a list item",
                                               line_break: "\n",
                                               attached: [{ paragraph: { lines: [{ text: "With attached paragraph.",
                                                                                   line_break: "\n" }] } },
                                                          { paragraph: { lines: [{ text: "And another attached paragraph.",
                                                                                   line_break: "\n" }] } }],
                                               nested: [] } }] } }
      expect(ast).to eq(obj)
    end

    it "parses nested list with paragraph attached" do
      content = <<~TEXT
        . Ordered list item 1
        . Ordered list item 2
        ** Nested list item A
        +
        Attached paragraph.
      TEXT

      ast = Asciidoc::ListTester.parse(content)
      items = ast[:list][:ordered]
      expect(items[0][:list_item][:text]).to eq("Ordered list item 1")
      expect(items[1][:list_item][:nested][0][:list][:unordered][0][:list_item][:text]).to eq("Nested list item A")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "Ordered list item 1",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [] } },
                                { list_item: { marker: ".",
                                               text: "Ordered list item 2",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [{ list: { unordered: [{ list_item: { marker: "**",
                                                                                             text: "Nested list item A",
                                                                                             line_break: "\n",
                                                                                             attached: [{ paragraph: { lines: [{ text: "Attached paragraph.",
                                                                                                                                 line_break: "\n" }] } }],
                                                                                             nested: [] } }] } }] } }] } }

      expect(ast).to eq(obj)
    end

    it "parses nested list with multiline paragraph attached" do
      content = <<~TEXT
        . Ordered list item 1
        . Ordered list item 2
        ** Nested list item A
        +
        Attached paragraph
        that is also
        multiline.
      TEXT

      ast = Asciidoc::ListTester.parse(content)
      items = ast[:list][:ordered]
      expect(items[0][:list_item][:text]).to eq("Ordered list item 1")
      expect(items[1][:list_item][:nested][0][:list][:unordered][0][:list_item][:text]).to eq("Nested list item A")

      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "Ordered list item 1",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [] } },
                                { list_item: { marker: ".",
                                               text: "Ordered list item 2",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [{ list: { unordered: [{ list_item: { marker: "**",
                                                                                             text: "Nested list item A",
                                                                                             line_break: "\n",
                                                                                             attached: [{ paragraph: { lines: [{ text: "Attached paragraph", line_break: "\n" },
                                                                                                                               { text: "that is also",
                                                                                                                                 line_break: "\n" },
                                                                                                                               { text: "multiline.",
                                                                                                                                 line_break: "\n" }] } }],
                                                                                             nested: [] } }] } }] } }] } }

      expect(ast).to eq(obj)
    end

    it "parses item with both attached and nested" do
      content = <<~ADOC
        . Ordered list item 1
        . Ordered list item 2
        +
        Attached paragraph.
        ** Nested list item A
      ADOC

      ast = Asciidoc::ListTester.parse(content)
      obj = { list: { ordered: [{ list_item: { marker: ".",
                                               text: "Ordered list item 1",
                                               line_break: "\n",
                                               attached: [],
                                               nested: [] } },
                                { list_item: { marker: ".",
                                               text: "Ordered list item 2",
                                               line_break: "\n",
                                               attached: [{ paragraph: { lines: [{ text: "Attached paragraph.",
                                                                                   line_break: "\n" }] } }],
                                               nested: [{ list: { unordered: [{ list_item: { marker: "**",
                                                                                             text: "Nested list item A",
                                                                                             line_break: "\n",
                                                                                             attached: [],
                                                                                             nested: [] } }] } }] } }] } }
      expect(ast).to eq(obj)
    end
  end

  it "parses ordered list containing inline" do
    content = <<~DOC
      . Ordered list item *number one*
      . Ordered item #number two#
      . [[list_item_id]] Ordered last item _number three_
    DOC

    ast = Asciidoc::ListTester.parse(content)
    list_items = ast[:list][:ordered]

    expect(list_items.count).to eq(3)
    expect(list_items[0][:list_item][:text][0][:text]).to eq("Ordered list item ")
    expect(list_items[0][:list_item][:text][1][:bold_constrained][0][:text]).to eq("number one")
    expect(list_items[1][:list_item][:text][0][:text]).to eq("Ordered item ")
    expect(list_items[1][:list_item][:text][1][:highlight_constrained][0][:text]).to eq("number two")
    expect(list_items[2][:list_item][:id]).to eq("list_item_id")
    expect(list_items[2][:list_item][:text][0][:text]).to eq("Ordered last item ")
    expect(list_items[2][:list_item][:text][1][:italic_constrained][0][:text]).to eq("number three")
  end

  it "parses definition list" do
    content = <<~TEXT
      Clause:: 5.1
      Maps_27002_2013:: iso:5.1.1, iso:5.1.2

      This content block also contains some text
    TEXT

    ast = Asciidoc::ListTester.parse(content)
    obj = { list: { definition_list: [{ definition_list_item: { terms: [{ dlist_term: "Clause", delimiter: "::" }],
                                                                definition: "5.1" } },
                                      { definition_list_item: { terms: [{ dlist_term: "Maps_27002_2013",
                                                                          delimiter: "::" }],
                                                                definition: "iso:5.1.1, iso:5.1.2" } }] } }

    expect(ast).to eq(obj)
  end
end

module Asciidoc
  class ListTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) { (list | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text).first
    end
  end
end
