require_relative "admonition"
require_relative "attribute_list"
require_relative "bibliography"
require_relative "block"
require_relative "content"
require_relative "document_attributes"
require_relative "header"
require_relative "inline"
require_relative "list"
require_relative "paragraph"
require_relative "section"
require_relative "table"
# require_relative "include"

module Coradoc
  module Parser
    module Asciidoc
      module Base
        include Coradoc::Parser::Asciidoc::Admonition
        include Coradoc::Parser::Asciidoc::AttributeList
        include Coradoc::Parser::Asciidoc::Bibliography
        include Coradoc::Parser::Asciidoc::Block
        include Coradoc::Parser::Asciidoc::Content
        include Coradoc::Parser::Asciidoc::DocumentAttributes
        include Coradoc::Parser::Asciidoc::Header
        include Coradoc::Parser::Asciidoc::Inline
        include Coradoc::Parser::Asciidoc::List
        include Coradoc::Parser::Asciidoc::Paragraph
        include Coradoc::Parser::Asciidoc::Section
        include Coradoc::Parser::Asciidoc::Table

        def space?
          space.maybe
        end

        def space
          match('\s').repeat(1)
        end

        def text
          match("[^\n]").repeat(1)
        end

        def line_ending
          match("[\n]")
        end

        def endline
          newline | any.absent?
        end

        def newline
          # match["\r\n"].repeat(1)
          (match("\n") | match("\r\n")).repeat(1)
        end

        def newline_single
          (match("\n") | match("\r\n"))
        end

        def keyword
          (match("[a-zA-Z0-9_-]") | str(".")).repeat(1)
        end

        def empty_line
          match("^\n")
        end

        def digit
          match("[0-9]")
        end

        def digits
          match("[0-9]").repeat(1)
        end

        def word
          match("[a-zA-Z0-9_-]").repeat(1)
        end

        def words
          word >> (space? >> word).repeat
        end

        def rich_texts
          rich_text >> (space? >> rich_text).repeat
        end

        def rich_text
          (match("[a-zA-Z0-9_-]") | str(".") | str("*") | match("@")).repeat(1)
        end

        def email
          word >> str("@") >> word >> str(".") >> word
        end

        def special_character
          match("^[*_:=-]") | str("[#") | str("[[")
        end

        def date
          digit.repeat(2, 4) >> str("-") >>
            digit.repeat(1, 2) >> str("-") >> digit.repeat(1, 2)
        end

        def attr_name
          match("[^\t\s]").repeat(1)
        end

        def file_path
          match('[^\[]').repeat(1)
          # match("[a-zA-Z0-9_-]").repeat(1)
        end

        def include_directive
          (str("include::") >> 
            file_path.as(:path) >>
            attribute_list >>
          (line_ending)
          ).as(:include)
        end

        def inline_image
          (str("image::") >> 
            file_path.as(:path) >>
            attribute_list >>
          (line_ending)
          ).as(:inline_image)
        end

        def comment_line
          (str('//') >> str("/").absent? >>
            space? >>
            text.as(:comment_text) #>>
            # newline.as(:line_break)
            ).as(:comment_line)
        end

        def comment_block
          ( str('////') >> line_ending >>
          ((line_ending >> str('////')).absent? >> any
            ).repeat.as(:comment_text) >> 
          line_ending >> str('////')
          ).as(:comment_block)
        end
      end
    end
  end
end
