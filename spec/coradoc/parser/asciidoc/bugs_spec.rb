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
      ast = Coradoc::Parser::Base.new.parse(content)
      # pp ast

    end

    xit "some problem with nested blocks" do
      content =<<~TEXT
        .Source block (open block syntax)
        [source]
        --
        ====
        Text inside of a block.
        ====
        --
      TEXT
      ast = Coradoc::Parser::Base.new.parse(content)
    # pp ast
    end
  end
end
