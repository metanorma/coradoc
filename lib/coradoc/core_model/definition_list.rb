# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a definition list
    #
    # DefinitionList contains terms and their definitions.
    # This maps to Kramdown definition lists and AsciiDoc labeled lists.
    #
    # @example Creating a definition list
    #   list = CoreModel::DefinitionList.new(
    #     items: [
    #       DefinitionItem.new(term: "API", definitions: ["Application Programming Interface"]),
    #       DefinitionItem.new(term: "REST", definitions: ["Representational State Transfer"])
    #     ]
    #   )
    class DefinitionList < Base
      # @!attribute items
      #   @return [Array<DefinitionItem>] the definition items
      attribute :items, DefinitionItem, collection: true

      private

      def comparable_attributes
        super + %i[items]
      end
    end
  end
end
