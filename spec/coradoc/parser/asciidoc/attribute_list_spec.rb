require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::AttributeList" do
  describe ".parse" do
    it "parses various attribute lists" do
      parser = Asciidoc::AttributeListTester
      ast = parser.parse("[]")
      expect(ast).to eq([])

      ast = parser.parse("[a]")
      expect(ast).to eq([{ positional: "a" }])
      ast = parser.parse("[a,b]")
      expect(ast).to eq([{ positional: "a" }, { positional: "b" }])
      ast = parser.parse("[a,b,c]")
      expect(ast).to eq([{ positional: "a" }, { positional: "b" },
                         { positional: "c" }])
      ast = parser.parse("[a=b]")
      expect(ast).to eq([{ named: { named_key: "a", named_value: "b" } }])
      ast = parser.parse("[a,b=c]")
      expect(ast).to eq([{ positional: "a" },
                         { named: { named_key: "b", named_value: "c" } }])
      ast = parser.parse("[a,b,c=d]")
      expect(ast).to eq([{ positional: "a" }, { positional: "b" },
                         { named: { named_key: "c", named_value: "d" } }])
      ast = parser.parse("[a,b=c,d=e]")
      obj = [{ positional: "a" },
             { named: { named_key: "b", named_value: "c" } },
             { named: { named_key: "d", named_value: "e" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("[a,b,c=d,e=f]")
      obj = [{ positional: "a" },
             { positional: "b" },
             { named: { named_key: "c", named_value: "d" } },
             { named: { named_key: "e", named_value: "f" } }]
      expect(ast).to eq(obj)

      ast = parser.parse("[a='single quoted']")
      obj = [{ named: { named_key: "a",
                        named_value: "'single quoted'" } }]
      expect(ast).to eq(obj)

      ast = parser.parse('[a="double quoted"]')
      obj = [{ named: { named_key: "a",
                        named_value: '"double quoted"' } }]
      expect(ast).to eq(obj)
    end
  end
end

module Asciidoc
  class AttributeListTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) { (attribute_list | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)[0][:attribute_list][:attribute_array]
    end
  end
end
