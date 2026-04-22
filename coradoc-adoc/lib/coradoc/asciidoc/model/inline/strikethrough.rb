# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Strikethrough inline text formatting for AsciiDoc documents.
        #
        # Strikethrough text is rendered with line-through role: [.line-through]#text#.
        #
        # @!attribute [r] content
        #   @return [String, Array<Lutaml::Model::Serializable>] The text content to format as strikethrough
        #
        # @!attribute [r] text
        #   @return [String] Alternative text attribute (aliased to content)
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: false)
        #
        # @example Create strikethrough text
        #   strikethrough = Coradoc::AsciiDoc::Model::Inline::Strikethrough.new
        #   strikethrough.content = "Deleted text"
        #   strikethrough.to_adoc # => "[.line-through]#Deleted text#"
        #
        class Strikethrough < Base
          attribute :content,
                    Lutaml::Model::Serializable,
                    default: -> { nil },
                    polymorphic: [
                      Lutaml::Model::Type::String,
                      :array
                    ]
          attribute :text, :string, default: -> { nil }
          attribute :unconstrained, :boolean, default: -> { false }
        end
      end
    end
  end
end
