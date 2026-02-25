# frozen_string_literal: true

module Coradoc
  module Markdown
    # DefinitionTerm model representing a term in a definition list.
    #
    # A term can have multiple definitions and can span multiple lines.
    # Terms can also have IAL attributes attached.
    #
    # @example Simple term
    #   term = Coradoc::Markdown::DefinitionTerm.new(text: "kramdown")
    #
    class DefinitionTerm < Base
      # The term text content
      attribute :text, :string

      # Definitions for this term
      attribute :definitions, Coradoc::Markdown::DefinitionItem, collection: true, default: []
    end
  end
end
