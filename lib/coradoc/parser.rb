require_relative "parser/base"

module Coradoc
  module Parser
    class << self

      # @param [String] filename The filename of the Asciidoc file to parse
      # @return [AST] The parsed AST object
      def parse_file(filename)
        Coradoc::Parser::Base.parse_file(filename)
      end

      # @param [String] string The Asciidoc string to parse
      # @return [AST] The parsed AST object
      def parse(string)
        Coradoc::Parser::Base.parse(string)
      end
    end
  end
end
