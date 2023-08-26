module Coradoc
  module Parser
    module Asciidoc
      module Base
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
          match["\r\n"].repeat(1)
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

        def attribute_name
          match("[a-zA-Z0-9_-]").repeat(1)
        end

        def attribute_value
          text | str("")
        end

        def special_character
          match("^[*_:=-]") | str("[#") | str("[[")
        end

        def date
          digit.repeat(2, 4) >> str("-") >>
            digit.repeat(1, 2) >> str("-") >> digit.repeat(1, 2)
        end
      end
    end
  end
end
