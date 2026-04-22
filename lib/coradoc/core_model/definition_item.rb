# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a definition list item (term with definitions)
    #
    # DefinitionItem contains a term and its associated definitions.
    #
    # @example Creating a definition item
    #   item = CoreModel::DefinitionItem.new(
    #     term: "API",
    #     definitions: ["Application Programming Interface", "A set of protocols"]
    #   )
    class DefinitionItem < Base
      # @!attribute term
      #   @return [String, nil] the term being defined
      attribute :term, :string

      # @!attribute definitions
      #   @return [Array<String>] the definitions for the term
      attribute :definitions, :string, collection: true

      private

      def comparable_attributes
        super + %i[term definitions]
      end
    end
  end
end
