# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Monospace inline text formatting for AsciiDoc documents.
        #
        # Monospace text is rendered with backticks: `monospace text`.
        # Used for code, commands, and technical terms.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as monospace
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: true)
        #
        # @example Create monospace text
        #   mono = Coradoc::AsciiDoc::Model::Inline::Monospace.new
        #   mono.content = "code"
        #   mono.to_adoc # => "`code`"
        #
        # @see Coradoc::AsciiDoc::Model::Inline::Bold Bold text
        # @see Coradoc::AsciiDoc::Model::Inline::Italic Italic text
        #
        class Monospace < Base
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
