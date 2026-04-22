# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Subscript inline text formatting for AsciiDoc documents.
        #
        # Subscript text is rendered with tildes: ~subscript~.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as subscript
        #
        # @example Create subscript text
        #   sub = Coradoc::AsciiDoc::Model::Inline::Subscript.new
        #   sub.content = "2"
        #   sub.to_adoc # => "~2~"
        #
        # @see Coradoc::AsciiDoc::Model::Inline::Superscript Superscript text
        #
        class Subscript < Base
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
