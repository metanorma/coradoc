# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Shared module for models that carry mixed content (strings + InlineElements)
    # as a children array alongside a string content attribute.
    #
    # Included by Block, ListItem, and TableCell to provide:
    # - children array management (reader, writer, initialize)
    # - renderable_content: prefers children when they contain non-string objects,
    #   falls back to the content attribute otherwise
    # - flat_text: one-line plain-text extraction from mixed content
    # - to_hash: includes children in serialization output
    module ChildrenContent
      def self.included(base)
        base.attr_reader :children
      end

      def initialize(args = {})
        @children = args.delete(:children) || []
        super(args)
      end

      def children=(value)
        @children = value || []
      end

      # Get content for rendering, preferring children over content.
      # When children are all plain strings, use the content attribute instead
      # since it already has proper spacing between lines.
      def renderable_content
        return content if children.nil? || children.none?
        return content if content && children.all?(String)

        children
      end

      # Flatten renderable_content to a single plain-text string.
      # InlineElements are rendered as their content.to_s.
      def flat_text
        rc = renderable_content
        case rc
        when String then rc
        when Array then rc.map { |c| c.is_a?(String) ? c : c.content.to_s }.join
        else rc.to_s
        end
      end

      def to_hash
        super.tap do |h|
          h['children'] = serialize_children(children) if children&.any?
        end
      end
    end
  end
end
