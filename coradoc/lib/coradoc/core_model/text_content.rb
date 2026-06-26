# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Wrapper for plain-text strings in mixed-content children arrays.
    #
    # Enables every child in a children collection to be a typed Base
    # instance, so that children can be declared as
    #   attribute :children, Base, collection: true
    # matching StructuralElement's proven pattern.
    #
    # @example
    #   TextContent.new(text: "Hello, world")
    class TextContent < Base
      attribute :text, :string

      def to_s
        text.to_s
      end

      def whitespace_only?
        text.to_s.strip.empty?
      end
    end
  end
end
