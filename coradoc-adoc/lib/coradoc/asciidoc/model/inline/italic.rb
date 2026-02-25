# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Italic inline text formatting for AsciiDoc documents.
        #
        # Italic text is rendered with underscores: _italic text_.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as italic
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: true)
        #
        # @example Create italic text
        #   italic = Coradoc::AsciiDoc::Model::Inline::Italic.new
        #   italic.content = "Emphasized text"
        #   italic.to_adoc # => "_Emphasized text_"
        #
        # @see Coradoc::AsciiDoc::Model::Inline::Bold Bold text
        # @see Coradoc::AsciiDoc::Model::Inline::Monospace Monospace text
        #
        class Italic < Base
          attribute :content,
                    Lutaml::Model::Serializable,
                    default: -> { nil },
                    polymorphic: [
                      Lutaml::Model::Type::String,
                      :array
                    ]
          attribute :unconstrained, :boolean, default: -> { true }
        end
      end
    end
  end
end
