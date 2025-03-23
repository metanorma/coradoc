require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::Inline" do
  describe ".parse" do
    it "parses various inline text formattings" do
      parser = Asciidoc::InlineTextFormattingTester

      ast = parser.parse("text without any formatting")
      expect(ast).to eq("text without any formatting")

      ast = parser.parse("*bold*")
      expect(ast).to eq([{ bold_constrained: [{ text: "bold" }] }])

      ast = parser.parse("**bold2**")
      expect(ast).to eq([{ bold_unconstrained: [{ text: "bold2" }] }])

      ast = parser.parse("_italic_")
      expect(ast).to eq([{ italic_constrained: [{ text: "italic" }] }])

      ast = parser.parse("__italic2__")
      expect(ast).to eq([{ italic_unconstrained: [{ text: "italic2" }] }])

      ast = parser.parse("#highlight#")
      expect(ast).to eq([{ highlight_constrained: [{ text: "highlight" }] }])

      ast = parser.parse("##highlight2##")
      expect(ast).to eq([{ highlight_unconstrained: [{ text: "highlight2" }] }])

      ast = parser.parse("^superscript^")
      expect(ast).to eq([{ superscript: [{ text: "superscript" }] }])

      ast = parser.parse("~subscript~")
      expect(ast).to eq([{ subscript: [{ text: "subscript" }] }])

      ast = parser.parse("[small]#span#")
      obj = [{ span_constrained: { attribute_list: { attribute_array: [{ positional: "small" }] },
                                   text: "span" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("[small]##span2##")
      obj = [{ span_unconstrained: { attribute_list: { attribute_array: [{ positional: "small" }] },
                                     text: "span2" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("{attribute-reference}")
      expect(ast).to eq([{ attribute_reference: "attribute-reference" }])

      ast = parser.parse("<<cross-reference>>")
      expect(ast).to eq([{ cross_reference: [{ href_arg: "cross-reference" }] }])

      ast = parser.parse("*bold* starting the line")
      obj = [{ bold_constrained: [{ text: "bold" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("**bold** starting the line")
      obj = [{ bold_unconstrained: [{ text: "bold" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("_italic_ starting the line")
      obj = [{ italic_constrained: [{ text: "italic" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("__italic2__ starting the line")
      obj = [{ italic_unconstrained: [{ text: "italic2" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("#highlight# starting the line")
      obj = [{ highlight_constrained: [{ text: "highlight" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("##highlight2## starting the line")
      obj = [{ highlight_unconstrained: [{ text: "highlight2" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("^superscript^ then some text")
      obj = [{ superscript: [{ text: "superscript" }] },
             { text: " then some text" }]
      expect(ast).to eq(obj)

      ast = parser.parse("~subscript~ then some text")
      obj = [{ subscript: [{ text: "subscript" }] },
             { text: " then some text" }]
      expect(ast).to eq(obj)

      ast = parser.parse("[small]#span# starting the line")
      obj = [{ span_constrained: { attribute_list: { attribute_array: [{ positional: "small" }] },
                                   text: "span" } },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("[small]##span2## starting the line")
      obj = [{ span_unconstrained: { attribute_list: { attribute_array: [{ positional: "small" }] },
                                     text: "span2" } },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("{attribute-reference} starting the line")
      obj = [{ attribute_reference: "attribute-reference" },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("<<cross-reference>> starting the line")
      obj = [{ cross_reference: [{ href_arg: "cross-reference" }] },
             { text: " starting the line" }]
      expect(ast).to eq(obj)

      ast = parser.parse("[underline]#span# with text")
      obj = [{ span_constrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                   text: "span" } },
             { text: " with text" }]
      expect(ast).to eq(obj)

      ast = parser.parse("[underline]##span2## with text")
      obj = [{ span_unconstrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                     text: "span2" } },
             { text: " with text" }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with *bold*")
      obj = [{ text: "line with " },
             { bold_constrained: [{ text: "bold" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with**bold**")
      obj = [{ text: "line with" },
             { bold_unconstrained: [{ text: "bold" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with _italic_")
      obj = [{ text: "line with " },
             { italic_constrained: [{ text: "italic" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with __italic2__")
      obj = [{ text: "line with " },
             { italic_unconstrained: [{ text: "italic2" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with #highlight#")
      obj = [{ text: "line with " },
             { highlight_constrained: [{ text: "highlight" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with ##highlight2##")
      obj = [{ text: "line with " },
             { highlight_unconstrained: [{ text: "highlight2" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before ^superscript^")
      obj = [{ text: "text before " },
             { superscript: [{ text: "superscript" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before ~subscript~")
      obj = [{ text: "text before " },
             { subscript: [{ text: "subscript" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with *bold* #highlight#")
      obj = [{ text: "line with " },
             { bold_constrained: [{ text: "bold" }] },
             { text: " " },
             { highlight_constrained: [{ text: "highlight" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with [underline]#span#")
      obj = [{ text: "line with " },
             { span_constrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                   text: "span" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with [underline]##span2##")
      obj = [{ text: "line with " },
             { span_unconstrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                     text: "span2" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with <<cross-reference>>")
      obj = [{ text: "line with " },
             { cross_reference: [{ href_arg: "cross-reference" }] }]
      expect(ast).to eq(obj)

      ast = parser.parse("before *bold* after")
      obj = [{ text: "before " },
             { bold_constrained: [{ text: "bold" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before **bold2** after")
      obj = [{ text: "before " },
             { bold_unconstrained: [{ text: "bold2" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before _italic_ after")
      obj = [{ text: "before " },
             { italic_constrained: [{ text: "italic" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before __italic2__ after")
      obj = [{ text: "before " },
             { italic_unconstrained: [{ text: "italic2" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before #highlight# after")
      obj = [{ text: "before " },
             { highlight_constrained: [{ text: "highlight" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before ##highlight2## after")
      obj = [{ text: "before " },
             { highlight_unconstrained: [{ text: "highlight2" }] },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before ^superscript^ and after")
      obj = [{ text: "text before " },
             { superscript: [{ text: "superscript" }] },
             { text: " and after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before ~subscript~ and after")
      obj = [{ text: "text before " },
             { subscript: [{ text: "subscript" }] },
             { text: " and after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before <<cross-reference>>  and after")
      obj = [{ text: "text before " },
             { cross_reference: [{ href_arg: "cross-reference" }] },
             { text: "  and after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("text before <<cross-reference>>, <<cross-ref2>> and after")
      obj = [{ text: "text before " },
             { cross_reference: [{ href_arg: "cross-reference" }] },
             { text: ", " },
             { cross_reference: [{ href_arg: "cross-ref2" }] },
             { text: " and after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before [underline]#span# after")
      obj = [{ text: "before " },
             { span_constrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                   text: "span" } },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("before [underline]##span2## after")
      obj = [{ text: "before " },
             { span_unconstrained: { attribute_list: { attribute_array: [{ positional: "underline" }] },
                                     text: "span2" } },
             { text: " after" }]
      expect(ast).to eq(obj)

      ast = parser.parse("line with**bold** ##highlight##")
      obj = [{ text: "line with" },
             { bold_unconstrained: [{ text: "bold" }] },
             { text: " " },
             { highlight_unconstrained: [{ text: "highlight" }] }]
      expect(ast).to eq(obj)

      # TODO
      parser.parse("_*bold*_")

      ast = parser.parse("footnote:[some text]")
      expect(ast).to eq([{ footnote: "some text" }])

      ast = parser.parse("footnote:some_id[some text]")
      expect(ast).to eq([{ id: "some_id", footnote: "some text" }])

      parser.parse("footnote:[some text *with bold*]")
    end
    it "parses cross-references" do
      parser = Asciidoc::InlineTextFormattingTester

      ast = parser.parse("<<xref_anchor>>")
      expect(ast).to eq([{ cross_reference: [{ href_arg: "xref_anchor" }] }])

      ast = parser.parse("<<xref_anchor,display text>>")
      expect(ast).to eq([{ cross_reference: [{ href_arg: "xref_anchor" },
                                             { text: "display text" }] }])

      ast = parser.parse("<<xref_anchor,section=1>>")
      expect(ast).to eq([{ cross_reference: [{ href_arg: "xref_anchor" },
                                             { key: "section",
delimiter: "=", value: "1" }] }])
    end
  end
end

module Asciidoc
  class InlineTextFormattingTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) { (text_any | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
