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

        # def line_break
        #   match["\r\n"]
        # end

        def keyword
          (match("[a-zA-Z0-9_-]") | str(".")).repeat(1)
        end

        # def text_line
        #   special_character.absent? >>
        #   match("[^\n]").repeat(1).as(:text) >>
        #   line_ending.as(:break)
        # end

        # rule(:space) { match('\s') }
        # rule(:space?) { spaces.maybe }
        # rule(:spaces) { space.repeat(1) }
        def empty_line
          match("^\n")
        end
        #

        #
        # rule(:inline_element) { text }
        # rule(:text) { match("[^\n]").repeat(1) }
        def digits
          match("[0-9]").repeat(1)
        end

        def word
          match("[a-zA-Z0-9_-]").repeat(1)
        end

        def words
          word >> (space? >> word).repeat
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
      end
    end
  end
end
