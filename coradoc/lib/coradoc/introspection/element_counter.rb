# frozen_string_literal: true

module Coradoc
  module Introspection
    # Visitor that walks a document and counts each CoreModel node by
    # its type key. Used by Introspection.count_element_types to back
    # the +Coradoc.document_stats+ API.
    #
    # Typed StructuralElement / Block nodes are counted under their
    # +element_type+ (semantic identity). Other nodes fall back to a
    # snake_case rendering of their class name.
    class ElementCounter < Visitor::Base
      def initialize
        @counts = Hash.new(0)
      end

      attr_reader :counts

      def visit(element)
        return super(element) unless element.is_a?(CoreModel::Base)

        @counts[type_key_for(element)] += 1
        super(element)
      end

      private

      def type_key_for(element)
        if typed_node?(element) && element.element_type
          element.element_type
        else
          snake_case(element.class.name)
        end
      end

      def typed_node?(element)
        element.is_a?(CoreModel::StructuralElement) || element.is_a?(CoreModel::Block)
      end

      def snake_case(class_name)
        class_name.split('::').last
                  .gsub(/([A-Z])/, '_\1')
                  .downcase
                  .sub(/^_/, '')
      end
    end
  end
end
