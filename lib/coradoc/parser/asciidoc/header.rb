require "coradoc/parser/asciidoc/base"

module Coradoc
  module Parser
    module Asciidoc
      module Header
        include Coradoc::Parser::Asciidoc::Base

        # Header
        def header
          match("=") >> space? >> text.as(:title) >> newline >>
          author.maybe.as(:author) >> revision.maybe.as(:revision)
        end

        # Author
        def author
          words.as(:first_name) >> str(",") >> space? >> words.as(:last_name) >>
          space? >> str("<") >> email.as(:email) >> str(">") >> endline
        end

        # Revision
        def revision
          (word >> (str(".") >> word).maybe).as(:number) >>
          str(",") >> space? >> word.as(:date) >>
          str(":") >> space? >> words.as(:remark) >> newline
        end
      end
    end
  end
end
