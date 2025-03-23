require "spec_helper"

RSpec.describe "Coradoc::Parser::Asciidoc::List" do
  describe "parsing problem not fixed yet: " do
    xit "problem with parsing attribute_list before block in between two lists latter of which has block attached to it" do
      content = <<~ADOC
        . Unordered list item 1

        [reviewer=ISO]
        ****
        block content
        ****

        * Unordered list item 1
        +
        ====
        block attached
        ====
      ADOC
      Coradoc::Parser::Base.new.parse(content)
    end

    it "some problem with nested blocks" do
      content = <<~TEXT
        .Source block (open block syntax)
        [source]
        --
        ====
        Text inside of a block.
        ====
        --
      TEXT
      ast = Coradoc::Parser::Base.new.parse(content)
      expect(ast[:document][0][:block][:lines][0][:block][:lines][0][:text]).to eq("Text inside of a block.")
    end
  end
end
