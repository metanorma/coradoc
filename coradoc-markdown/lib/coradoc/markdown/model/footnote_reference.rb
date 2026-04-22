# frozen_string_literal: true

module Coradoc
  module Markdown
    # FootnoteReference model representing an inline footnote reference.
    #
    # Syntax: `[^name]` anywhere in text
    #
    # @example
    #   ref = Coradoc::Markdown::FootnoteReference.new(id: "1")
    #
    class FootnoteReference < Base
      # The footnote identifier
      attribute :id, :string

      # Serialize to Markdown
      def to_md
        "[^#{id}]"
      end
    end
  end
end
