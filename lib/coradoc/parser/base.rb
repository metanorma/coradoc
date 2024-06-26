require "parslet"
require "parslet/convenience"


require_relative "asciidoc/attribute_list"
require_relative "asciidoc/base"
require_relative "asciidoc/block"
require_relative "asciidoc/content"
require_relative "asciidoc/document_attributes"
require_relative "asciidoc/header"
require_relative "asciidoc/inline"
require_relative "asciidoc/list"
require_relative "asciidoc/paragraph"
require_relative "asciidoc/section"
require_relative "asciidoc/table"

module Coradoc
  module Parser
    class Base < Parslet::Parser
      include Coradoc::Parser::Asciidoc::AttributeList
      include Coradoc::Parser::Asciidoc::Base
      include Coradoc::Parser::Asciidoc::Block
      include Coradoc::Parser::Asciidoc::Content
      include Coradoc::Parser::Asciidoc::DocumentAttributes
      include Coradoc::Parser::Asciidoc::Header
      include Coradoc::Parser::Asciidoc::Inline
      include Coradoc::Parser::Asciidoc::List
      include Coradoc::Parser::Asciidoc::Paragraph
      include Coradoc::Parser::Asciidoc::Section
      include Coradoc::Parser::Asciidoc::Table

      root :document
      rule(:document) do
        (
          bibliography | 
          # attribute_list.as(:attribute_list) |
          comment_block |
          comment_line |
          block.as(:block) |
          include_directive |
          document_attributes |
          section.as(:section) |
          paragraph |
          list |
          header.as(:header) |
          empty_line.as(:line_break) |
          any.as(:unparsed)
        ).repeat(1).as(:document)
      end

      def self.parse(filename)
        content = File.read(filename)
        new.parse(content)
      rescue Parslet::ParseFailed => failure
        puts failure.parse_failure_cause.ascii_tree
      end
    end
  end
end
