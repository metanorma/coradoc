# frozen_string_literal: true

require "coradoc"
 
# This works with the update to Lutaml Model.
def parse(str)
  ast = Coradoc::Parser::Base.new.parse(str)
  result = Coradoc::Transformer.transform(ast)

  {
    ast:,
    result:,
  }
end

def parse_file(file_path = "spec/fixtures/sample.adoc")
  str = File.read(file_path)
  parse(str)
end


def menu
  puts <<~EOM
  🔨 Welcome to Coradoc ⨯ \x1b[31;1m#{$0}\x1b[m!

    parse(str)        - Given an asciidoc string, return AST and doc model
    parse_file(file)  - Given a file path, return AST and doc model

  [[general commands]]

    menu              - prints this menu

  EOM
end

menu
