# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Single-line comment element for AsciiDoc documents.
      #
      # Comment lines start with double slash (//) and are not included
      # in the final document output.
      #
      # @!attribute [r] text
      #   @return [String] The comment text
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create a comment line
      #   comment = Coradoc::AsciiDoc::Model::CommentLine.new
      #   comment.text = "This is a comment"
      #   comment.to_adoc # => "// This is a comment\n"
      #
      # @see Coradoc::AsciiDoc::Model::CommentBlock Multi-line comments
      #
      class CommentLine < Base
        attribute :text, :string
        attribute :line_break, :string, default: -> { "\n" }
      end
    end
  end
end
