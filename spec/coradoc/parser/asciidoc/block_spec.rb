require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::AttributeList" do
  describe ".parse" do
    it "parses attribute list attached to a block" do
      parser = Asciidoc::BlockTester
      content = <<~TEXT
        [reviewer=ISO]
        ****
        block content
        ****
      TEXT
      ast = parser.parse(content)
      obj = [{ block: { attribute_list: { attribute_array: [{ named: { named_key: "reviewer",
                                                                       named_value: "ISO" } }] },
                        delimiter: "****",
                        lines: [{ text: "block content",
                                  line_break: "\n" }] } }]

      expect(ast).to eq(obj)
    end

    it "parses attribute list attached to a block with a list inside" do
      parser = Asciidoc::BlockTester
      content = <<~TEXT
        [reviewer=ISO]
        ****
        * block content
        ****
      TEXT
      parser.parse(content)
      [{ block: { attribute_list: { attribute_array: [{ named: { named_key: "reviewer",
                                                                 named_value: "ISO" } }] },
                  delimiter: "****",
                  lines: [{ text: "block content",
                            line_break: "\n" }] } }]

      # expect(ast).to eq(obj)
    end
  end
end

module Asciidoc
  class BlockTester < Coradoc::Parser::Asciidoc::Base
    rule(:document) { (block | any.as(:unparsed)).repeat(1) }
    root :document

    def self.parse(text)
      new.parse_with_debug(text)
    end
  end
end
