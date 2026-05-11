# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a definition term in a document
    #
    # Terms are used in definition lists, glossaries, and terminology
    # sections. They can have various types (acronym, symbol, preferred, etc.)
    # and support multi-language content.
    #
    # @example Creating a simple term
    #   term = CoreModel::Term.new(
    #     text: "API",
    #     type: "acronym",
    #     definition: "Application Programming Interface"
    #   )
    #
    # @example Creating a multi-language term
    #   term = CoreModel::Term.new(
    #     text: "computer",
    #     type: "preferred",
    #     lang: "en",
    #     definition: "An electronic device for processing data"
    #   )
    class Term < Base
      # @!attribute text
      #   @return [String, nil] the term text
      attribute :text, :string

      # @!attribute type
      #   @return [String, nil] term type ('acronym', 'symbol', 'preferred', 'admitted', 'deprecated')
      attribute :type, :string

      # @!attribute lang
      #   @return [String] language code (default: 'en')
      attribute :lang, :string, default: -> { 'en' }

      # @!attribute definition
      #   @return [String, nil] definition of the term
      attribute :definition, :string

      # @!attribute source
      #   @return [String, nil] source reference for the term
      attribute :source, :string

      private

      def comparable_attributes
        super + %i[text type lang definition]
      end
    end
  end
end
