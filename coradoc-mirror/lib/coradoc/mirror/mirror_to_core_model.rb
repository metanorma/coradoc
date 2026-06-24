# frozen_string_literal: true

module Coradoc
  module Mirror
    # Transforms ProseMirror-compatible Mirror nodes back into CoreModel.
    #
    # Dispatch is delegated to ReverseBuilder (node-level) and
    # MarkReverseBuilder (mark-level) — adding a new node or mark type is
    # done by registering a new Builder class, with no edit to this file
    # (OCP). ReverseBuilder and MarkReverseBuilder are autoloaded from
    # coradoc/mirror.rb; referencing them here triggers load of the
    # registry files, which is where the built-in builders self-register.
    class MirrorToCoreModel
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

      # Mark dispatch goes through MarkReverseBuilder so adding a new
      # mark type is purely additive (OCP parity with node dispatch).
      # Unknown marks pass `inner` through unchanged.
      def apply_mark(inner, mark)
        builder_class = MarkReverseBuilder.lookup(mark.type)
        return inner unless builder_class

        builder_class.new.build(inner, mark)
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
