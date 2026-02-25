# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Highlight (marked) inline text formatting for AsciiDoc documents.
        #
        # Highlighted text is rendered with hash marks: #highlighted text#.
        # Used to draw attention to specific text.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to highlight
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: false)
        #
        # @example Create highlighted text
        #   highlight = Coradoc::AsciiDoc::Model::Inline::Highlight.new
        #   highlight.content = "Important"
        #   highlight.to_adoc # => "#Important#"
        #
        class Highlight < Base
          attribute :content,
                    Lutaml::Model::Serializable,
                    default: -> { nil },
                    polymorphic: [
                      Lutaml::Model::Type::String,
                      :array
                    ]
          attribute :unconstrained, :boolean, default: -> { false }
        end
      end
    end
  end
end
