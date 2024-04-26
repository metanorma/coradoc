require "parslet"
require "parslet/convenience"

require_relative "asciidoc/header"
require_relative "asciidoc/document_attributes"
require_relative "asciidoc/section"

module Coradoc
  module Parser
    class Base < Parslet::Parser
      include Coradoc::Parser::Asciidoc::Header
      include Coradoc::Parser::Asciidoc::DocumentAttributes
      include Coradoc::Parser::Asciidoc::Section

      root :document
      rule(:document) do
        (
          document_attributess.as(:document_attributes) |
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
