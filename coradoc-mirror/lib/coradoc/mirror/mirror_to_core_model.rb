# frozen_string_literal: true

require_relative 'reverse_builders'

module Coradoc
  module Mirror
    # Transforms ProseMirror-compatible Mirror nodes back into CoreModel.
    #
    # Dispatch is delegated to ReverseBuilder::REGISTRY — adding a new
    # Mirror node type is done by registering a new Builder class, with
    # no edit to this file (OCP).
    class MirrorToCoreModel
      # Mark type → CoreModel class mapping (OCP: add new marks by adding
      # a row here, or — for non-trivial marks like `link` — extending
      # the case statement in #apply_mark).
      SIMPLE_MARKS = {
        'strong' => CoreModel::BoldElement,
        'emphasis' => CoreModel::ItalicElement,
        'code' => CoreModel::MonospaceElement,
        'underline' => CoreModel::UnderlineElement,
        'strike' => CoreModel::StrikethroughElement,
        'subscript' => CoreModel::SubscriptElement,
        'superscript' => CoreModel::SuperscriptElement,
        'highlight' => CoreModel::HighlightElement
      }.freeze

      def call(mirror_node)
        build_node(mirror_node)
      end

      def build_node(node)
        builder_class = ReverseBuilder.lookup(node.type)
        raise Error, "Unknown mirror node type: #{node.type}" unless builder_class

        builder_class.new(self).build(node)
      end

      # ── Shared helpers (single source of truth — used by every
      # ReverseBuilder::Base subclass via delegation) ──

      def build_content(node)
        return [] unless node.content

        node.content.flat_map do |child|
          result = build_node(child)
          next [] if result.nil?

          result.is_a?(Array) ? result : [result]
        end
      end

      def apply_mark(inner, mark)
        klass = SIMPLE_MARKS[mark.type]
        return klass.new(children: Array(inner)) if klass

        case mark.type
        when 'link'
          CoreModel::LinkElement.new(target: mark.href, children: Array(inner))
        when 'xref'
          CoreModel::CrossReferenceElement.new(target: mark.target, children: Array(inner))
        else
          inner
        end
      end

      def build_inline_children(node)
        return [] unless node.content

        node.content.filter_map do |child|
          next unless child.is_a?(Node)

          build_node(child)
        end
      end

      def extract_text(node)
        return node.text.to_s if node.is_a?(Node::Text)
        return '' unless node.content

        node.content.filter_map do |child|
          child.is_a?(Node) ? extract_text(child) : ''
        end.join
      end

      def inline_content(element)
        element.is_a?(CoreModel::InlineElement) ? element.content : element.to_s
      end
    end
  end
end
