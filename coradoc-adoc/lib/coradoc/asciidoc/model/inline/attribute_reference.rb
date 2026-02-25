# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Attribute reference inline element for AsciiDoc documents.
        #
        # Attribute references insert the value of a document attribute.
        #
        # @!attribute [r] name
        #   @return [String] The attribute name to reference
        #
        # @example Create an attribute reference
        #   ref = Coradoc::AsciiDoc::Model::Inline::AttributeReference.new
        #   ref.name = "author"
        #   ref.to_adoc # => "{author}"
        #
        class AttributeReference < Base
          attribute :name, :string
        end
      end
    end
  end
end
