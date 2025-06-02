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
          # admonition_line |
          # audio |
          # bib_entry |
          # block |
          # block_image |
          # comment_block |
          # comment_line |
          # include_directive |
          # list |
          # paragraph |
          # table.as(:table) |
          # tag |
          # video |
          contents |
          section |
          document_attributes |
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
        warn e.parse_failure_cause.ascii_tree
      end
    end
  end
end
