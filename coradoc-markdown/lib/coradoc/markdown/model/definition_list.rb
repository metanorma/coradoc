# frozen_string_literal: true

module Coradoc
  module Markdown
    # DefinitionList model representing a Kramdown definition list.
    #
    # Definition lists consist of terms followed by one or more definitions.
    # The syntax uses `:` to start a definition.
    #
    # @example Simple definition list
    #   list = Coradoc::Markdown::DefinitionList.new(
    #     items: [
    #       Coradoc::Markdown::DefinitionTerm.new(
    #         text: "kramdown",
    #         definitions: [
    #           Coradoc::Markdown::DefinitionItem.new(content: "A Markdown parser")
    #         ]
    #       )
    #     ]
    #   )
    #
    # Syntax:
    #   term
    #   : definition content
    #
    #   multiple terms
    #   : first definition
    #   : second definition
    #
    class DefinitionList < Base
      # Terms with their definitions
      attribute :items, Coradoc::Markdown::DefinitionTerm, collection: true
    end
  end
end
