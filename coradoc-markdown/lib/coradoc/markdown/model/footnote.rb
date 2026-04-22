# frozen_string_literal: true

module Coradoc
  module Markdown
    # Footnote model representing a footnote definition or reference.
    #
    # Kramdown syntax:
    # - Reference: `[^1]` or `[^name]`
    # - Definition: `[^1]: Footnote text`
    #
    # @example Footnote definition
    #   fn = Coradoc::Markdown::Footnote.new(
    #     id: "1",
    #     content: "This is a footnote"
    #   )
    #
    class Footnote < Base
      # The footnote identifier (number or name)
      attribute :id, :string

      # The footnote content
      attribute :content, :string

      # Inline content (can be array of elements)
      attribute :inline_content, :string, collection: true

      # Reference back to where this footnote is used
      attribute :backlink, :boolean, default: true
    end
  end
end
