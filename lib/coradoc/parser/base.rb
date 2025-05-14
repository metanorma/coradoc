require "digest"
require "parslet"
require "parslet/convenience"

require_relative "asciidoc/base"

module Coradoc
  module Parser
    class Base < Coradoc::Parser::Asciidoc::Base
      root :document
      rule(:document) do
        (
          admonition_line |
          bib_entry |
          block_image |
          tag |
          comment_block |
          comment_line |
          block |
          section |
          include_directive |
          document_attributes |
          list |
          table.as(:table) |
          paragraph |
          header.as(:header) |
          empty_line.as(:line_break) |
          any.as(:unparsed)
        ).repeat(1).as(:document)
      end

      # @param [String] filename The filename of the Asciidoc file to parse
      # @return [AST] The parsed AST object
      def self.parse_file(filename)
        parse(File.read(filename))
      end

      # @param [String] string The Asciidoc string to parse
      # @return [AST] The parsed AST object
      def self.parse(string)
        new.parse(string)
      rescue Parslet::ParseFailed => e
        puts e.parse_failure_cause.ascii_tree
      end
    end
  end
end
