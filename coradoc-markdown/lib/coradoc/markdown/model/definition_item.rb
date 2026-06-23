# frozen_string_literal: true

module Coradoc
  module Markdown
    # DefinitionItem model representing a single definition in a definition list.
    #
    # Each definition item contains the definition content and can have
    # nested blocks (paragraphs, code blocks, lists, etc.)
    #
    # @example Simple definition
    #   defn = Coradoc::Markdown::DefinitionItem.new(content: "A Markdown parser")
    #
    class DefinitionItem < Base
      # The definition content (text or nested blocks)
      attribute :content, :string

      # Inline content as typed Markdown elements (Code, Strong, Text, etc.).
      # When present, the Flat serializer renders these via
      # `ctx.serialize_inline_join` so inline formatting is preserved.
      attribute :inline_content, Coradoc::Markdown::Base, collection: true, default: []

      # Nested block content (paragraphs, code blocks, lists, etc.)
      attribute :blocks, :string, collection: true
    end
  end
end
