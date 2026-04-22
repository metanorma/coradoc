# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Definition list item for AsciiDoc definition/labeled lists.
        #
        # A DefinitionItem contains one or more terms and their associated
        # definitions. In AsciiDoc, this maps to the labeled list syntax:
        #
        #   Term 1:: Definition 1
        #   Term 2::: Definition 2 (deeper level)
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the definition item
        #
        # @!attribute [r] terms
        #   @return [Array<Term>] The terms being defined (can have multiple)
        #
        # @!attribute [r] contents
        #   @return [Array<TextElement>] The definitions/contents for the terms
        #
        # @example Create a definition list item
        #   item = Coradoc::AsciiDoc::Model::List::DefinitionItem.new
        #   item.terms << Coradoc::AsciiDoc::Model::Term.new(term: "API")
        #   item.contents << Coradoc::AsciiDoc::Model::TextElement.new("Application Programming Interface")
        #
        class DefinitionItem < Base
          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :terms, Coradoc::AsciiDoc::Model::Term, collection: true
          attribute :contents, Coradoc::AsciiDoc::Model::TextElement, collection: true

          def to_adoc(delimiter: '')
            Coradoc::AsciiDoc::Serializer.serialize(self, delimiter: delimiter)
          end
        end
      end
    end
  end
end
