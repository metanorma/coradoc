# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Single-line comment — editorial or hidden notes that do not render.
    #
    # Distinct from {CommentBlock} (multi-line). Round-trip fidelity for the
    # single-line vs. block distinction is preserved across formats that have
    # a single-line comment syntax (AsciiDoc `//`); formats without one (e.g.
    # Markdown) collapse both to `<!-- ... -->`.
    class CommentLine < Base
      def self.semantic_type
        :comment_line
      end

      def body_content?
        false
      end

      attribute :text, :string
    end
  end
end