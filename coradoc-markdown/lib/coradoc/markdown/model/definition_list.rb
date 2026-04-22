# frozen_string_literal: true

require_relative 'definition_term'
require_relative 'definition_item'

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

      # Serialize to Markdown
      def to_md
        items.map do |term|
          term_text = term.text.to_s
          defs = term.definitions.map do |defn|
            content = defn.content.to_s
            ": #{content}"
          end.join("\n")
          "#{term_text}\n#{defs}"
        end.join("\n\n")
      end
    end
  end
end
