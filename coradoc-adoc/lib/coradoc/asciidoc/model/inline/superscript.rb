# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Superscript inline text formatting for AsciiDoc documents.
        #
        # Superscript text is rendered with carets: ^superscript^.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as superscript
        #
        # @example Create superscript text
        #   sup = Coradoc::AsciiDoc::Model::Inline::Superscript.new
        #   sup.content = "TM"
        #   sup.to_adoc # => "^TM^"
        #
        # @see Coradoc::AsciiDoc::Model::Inline::Subscript Subscript text
        #
        class Superscript < Base
          attribute :content,
                    Lutaml::Model::Serializable,
                    default: -> { nil },
                    polymorphic: [
                      Lutaml::Model::Type::String,
                      :array
                    ]
        end
      end
    end
  end
end
