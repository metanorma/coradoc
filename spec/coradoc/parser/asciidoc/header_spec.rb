require "spec_helper"

RSpec.describe "Coradoc::Asciidoc::Header" do
  describe ".parse" do
    it "parses the header with title" do
      header = <<~TEXT
        = This is the title
      TEXT

      ast = Asciidoc::HeaderTester.parse(header)

      expect(ast.first[:title]).to eq("This is the title")
    end

    it "parses the header tile with author and revision" do
      header = <<~TEXT
        = This is the title
        Given name, Last name <email@example.com>
        1.0, 2023-02-23: Version comment note
        :string-attribute: this has to be a string
      TEXT

      ast = Asciidoc::HeaderTester.parse(header)

      expect(ast.first[:title]).to eq("This is the title")
      expect(ast.first[:author][:first_name]).to eq("Given name")
      expect(ast.first[:author][:last_name]).to eq("Last name")
      expect(ast.first[:author][:email]).to eq("email@example.com")
    end
  end

  module Asciidoc
    class HeaderTester < Coradoc::Parser::Asciidoc::Base
      rule(:document) do
        (header | any.as(:unparsed)).repeat(1)
      end
      root :document

      def self.parse(text)
        new.parse_with_debug(text)
      end
    end
  end
end
