# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Span inline element for applying styles to text in AsciiDoc documents.
        #
        # Spans allow applying roles and custom attributes to inline text.
        #
        # @!attribute [r] text
        #   @return [String] The text content
        #
        # @!attribute [r] role
        #   @return [String, nil] The CSS role to apply
        #
        # @!attribute [r] attributes
        #   @return [Coradoc::AsciiDoc::Model::AttributeList, nil] Additional attributes
        #
        # @!attribute [r] unconstrained
        #   @return [Boolean] Whether to use unconstrained formatting (default: false)
        #
        # @example Create a span with a role
        #   span = Coradoc::AsciiDoc::Model::Inline::Span.new
        #   span.text = "Important text"
        #   span.role = "red"
        #   span.to_adoc # => "[.red]#Important text#"
        #
        class Span < Base
          attribute :text, :string
          attribute :role, :string
          attribute :attributes, Coradoc::AsciiDoc::Model::AttributeList
          attribute :unconstrained, :boolean, default: -> { false }
        end
      end
    end
  end
end
