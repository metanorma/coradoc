require "parslet"
require "parslet/convenience"

require "coradoc/parser/asciidoc/header"
require "coradoc/parser/asciidoc/bibdata"
require "coradoc/parser/asciidoc/section"

module Coradoc
  module Parser
    class Base < Parslet::Parser
      include Coradoc::Parser::Asciidoc::Header
      include Coradoc::Parser::Asciidoc::Bibdata
      include Coradoc::Parser::Asciidoc::Section

      root :document
      rule(:document) do
        (
          bibdatas.as(:bibdata) |
          section.as(:section) |
          header.as(:header) |
          empty_line.as(:line_break) |
          any.as(:unparsed)
        ).repeat(1).as(:document)
      end

      def self.parse(filename)
        content = File.read(filename)
        new.parse_with_debug(content)
      end
    end
  end
end
