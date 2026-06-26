# frozen_string_literal: true

module Coradoc
  module LinkRewriter
    # Focused rewriting visitor for the CoreModel tree.
    #
    # The set of node types that carry link/xref targets is closed and
    # small: +LinkElement+, +CrossReferenceElement+, plus generic
    # +InlineElement+ instances whose +format_type+ is +'link'+ or
    # +'xref'+. That classification is owned polymorphically by
    # +InlineElement#link_kind+ — the visitor just calls it. Adding a
    # new link-bearing subclass means overriding +link_kind+ on it,
    # not editing a case/when here (OCP).
    #
    # Verbatim block types are also closed: +SourceBlock+, +ListingBlock+,
    # +LiteralBlock+, +PassBlock+, +StemBlock+. The visitor returns them
    # unchanged so the rewriter never sees link-shaped text that is, in
    # fact, raw code/math.
    #
    # Dispatch is class-based (no +respond_to?+ duck-typing). Unrecognized
    # classes are returned unchanged — the visitor is closed by design.
    class Visitor
      # Verbatim block classes — content is raw, no link semantics.
      VERBATIM_TYPES = [
        Coradoc::CoreModel::SourceBlock,
        Coradoc::CoreModel::ListingBlock,
        Coradoc::CoreModel::LiteralBlock,
        Coradoc::CoreModel::PassBlock,
        Coradoc::CoreModel::StemBlock
      ].freeze

      # Structural/container classes that own a child collection. Each
      # entry maps the class to the reader method that exposes its
      # children. MECE — every "recurse into the children" case lands
      # in this table. Exposed as a public constant so spec helpers
      # and other visitors can mirror the same paths without restating
      # the dispatch (DRY).
      CONTAINER_TYPES = {
        Coradoc::CoreModel::DocumentElement => :children,
        Coradoc::CoreModel::SectionElement => :children,
        Coradoc::CoreModel::PreambleElement => :children,
        Coradoc::CoreModel::HeaderElement => :children,
        Coradoc::CoreModel::Block => :children,
        Coradoc::CoreModel::ListBlock => :items,
        Coradoc::CoreModel::ListItem => :children,
        Coradoc::CoreModel::Table => :rows,
        Coradoc::CoreModel::TableRow => :cells,
        Coradoc::CoreModel::TableCell => :children,
        Coradoc::CoreModel::DefinitionList => :items,
        Coradoc::CoreModel::Toc => :entries,
        Coradoc::CoreModel::Bibliography => :entries,
        Coradoc::CoreModel::AnnotationBlock => :children
      }.freeze

      def initialize(rewriter)
        @rewriter = rewriter
      end

      # Entry point. Always returns a NEW root node — even Identity
      # callers can rely on object identity to confirm the rewrite ran.
      def visit_document(document)
        return document unless document.is_a?(Coradoc::CoreModel::Base)

        result = visit_subtree(document)
        result.equal?(document) ? document.dup : result
      end

      private

      def visit_subtree(node)
        return node if VERBATIM_TYPES.any? { |type| node.is_a?(type) }
        return rewrite_inline(node) if node.is_a?(Coradoc::CoreModel::InlineElement)

        reader = reader_for(node)
        return node unless reader

        rewrite_collection(node, reader)
      end

      # Look up the children-reader method for +node+. Returns nil for
      # unrecognized classes (no duck-typing — the CONTAINER_TYPES
      # table is the single source of truth).
      def reader_for(node)
        CONTAINER_TYPES.each do |klass, reader|
          return reader if node.is_a?(klass)
        end
        nil
      end

      def rewrite_collection(node, attr_name)
        original = node.public_send(attr_name)
        return node if original.nil? || original.empty?

        rewritten = original.map { |child| visit_subtree(child) }
        return node if unchanged?(rewritten, original)

        rebuild_with(node, attr_name => rewritten)
      end

      # Inline dispatch. Typed LinkElement / CrossReferenceElement are
      # always candidates; generic InlineElement instances must declare a
      # matching format_type. Other typed subclasses (Bold, Italic, …)
      # are walked for nested inlines instead of being rewritten.
      def rewrite_inline(inline)
        kind = inline.link_kind

        rewritten_target = rewrite_target(inline, kind)
        rewritten_nested = rewrite_nested(inline)

        return inline if rewritten_target.nil? && rewritten_nested.nil?

        overrides = {}
        overrides[:target] = rewritten_target unless rewritten_target.nil?
        overrides[:nested_elements] = rewritten_nested unless rewritten_nested.nil?
        rebuild_with(inline, overrides)
      end

      def rewrite_target(inline, kind)
        return nil unless kind

        target = inline.target
        return nil if target.nil? || target.empty?

        new_target = @rewriter.call(
          target: target,
          kind: kind,
          context: { in_verbatim: false }
        )
        return nil if new_target == target

        new_target
      end

      def rewrite_nested(inline)
        nested = inline.nested_elements
        return nil if nested.nil? || nested.empty?

        rewritten = nested.map { |child| visit_subtree(child) }
        return nil if unchanged?(rewritten, nested)

        rewritten
      end

      def rebuild_with(node, overrides)
        duplicate = node.dup
        overrides.each { |key, value| duplicate.public_send("#{key}=", value) }
        duplicate
      end

      def unchanged?(rewritten, original)
        return false unless rewritten.length == original.length

        rewritten.each_with_index.all? { |node, i| node.equal?(original[i]) }
      end
    end
  end
end
