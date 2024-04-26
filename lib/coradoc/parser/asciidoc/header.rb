require_relative "base"

module Coradoc
  module Parser
    module Asciidoc
      module Header
        include Coradoc::Parser::Asciidoc::Base

        def header
          header_title >>
            author.maybe.as(:author) >>
            revision.maybe.as(:revision) >> newline.maybe
        end

        def header_title
          match("=") >> space? >> text.as(:title) >> newline
        end

        def author
          words.as(:first_name) >> str(",") >>
            space? >> words.as(:last_name) >>
            space? >> str("<") >> email.as(:email) >> str(">") >> newline
        end

        def revision
          (word >> (str(".") >> word).maybe).as(:number) >>
            str(",") >> space? >> date.as(:date) >> str(":") >>
            space? >> words.as(:remark) >> newline
        end
      end
    end
  end
end
