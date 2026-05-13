# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Shared helpers for models that carry mixed-content children
    # (TextContent + InlineElement + Block instances) alongside a string
    # content attribute.
    #
    # Included by Block, ListItem, TableCell, and InlineElement.
    # The children attribute is declared as
    #   attribute :children, Base, collection: true
    # on each including class. This module overrides the setter to
    # auto-wrap raw strings as TextContent, keeping all callers simple.
    module ChildrenContent
      # Override the children= setter to auto-wrap strings as TextContent.
      # This is defined via define_method so it always overrides the
      # lutaml-generated setter, regardless of include order.
      def self.included(base)
        super

        base.define_method(:children=) do |value|
          wrapped = Array(value).map do |item|
            next nil if item.nil?
            next item if item.is_a?(CoreModel::Base)

            CoreModel::TextContent.new(text: item.to_s)
          end.compact
          instance_variable_set(:@children, wrapped)
        end
      end

      # Get content for rendering, preferring children over content.
      # When children are all TextContent (plain text), use the content
      # attribute instead since it already has proper spacing between lines.
      def renderable_content
        return content if children.nil? || children.none?
        return content if content && children.all?(TextContent)

        children
      end

      # Flatten renderable_content to a single plain-text string.
      def flat_text
        rc = renderable_content
        case rc
        when String then rc
        when Array then rc.map { |c| c.is_a?(TextContent) ? c.text : c.content.to_s }.join
        else rc.to_s
        end
      end
    end
  end
end
