# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Bold inline text formatting for AsciiDoc documents.
        #
        # Bold text is rendered with asterisks: *bold text*.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as bold
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: true)
        #
        # @example Create bold text
        #   bold = Coradoc::AsciiDoc::Model::Inline::Bold.new
        #   bold.content = "Important text"
        #   bold.to_adoc # => "*Important text*"
        #
        # @see Coradoc::AsciiDoc::Model::Inline::Italic Italic text
        # @see Coradoc::AsciiDoc::Model::Inline::Monospace Monospace text
        #
        class Bold < Base
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
