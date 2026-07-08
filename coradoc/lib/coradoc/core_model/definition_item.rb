# frozen_string_literal: true

module Coradoc
  module CoreModel
    class DefinitionItem < Base
      # Primary term (first term in source order). For multi-term `<dt>`'s
      # (AsciiDoc `term1::\nterm2::`), use {#terms} which carries the
      # full list. `term` is kept as the singular accessor for legacy
      # consumers; new consumers should prefer {#terms}.
      attribute :term, :string

      # All terms on this `<dt>`. Single-element for the common case;
      # multi-element for shared-`<dd>` AsciiDoc forms like
      #   term1::
      #   term2::
      #   shared definition
      # Order matches source order. Renderers emit one `<dt>` per entry.
      attribute :terms, :string, collection: true, default: []

      attribute :definitions, :string, collection: true
      attribute :nested, DefinitionList
      # `+`-continuation blocks attached to this dd in AsciiDoc source.
      # Each entry is a CoreModel block (ParagraphBlock, AdmonitionBlock,
      # etc.) that followed the dd after a `+` line — rendered as
      # additional children of the dd.
      attribute :attached_children, Base, collection: true, initialize_empty: true

      def initialize(args = {})
        @term_children = args.delete(:term_children) || []
        @definition_children = args.delete(:definition_children) || []
        super
        # Backward-compat: if caller passed only `term:` (no `terms:`),
        # seed the collection so #terms is always consistent with #term.
        self.terms = [term].compact if terms.empty? && !term.to_s.empty?
      end

      attr_reader :term_children, :definition_children

      def term_children=(value)
        @term_children = value || []
      end

      def definition_children=(value)
        @definition_children = value || []
      end

      def term_renderable
        return term if term_children.nil? || term_children.none?
        return term if term && term_children.all?(String)

        term_children
      end

      def definition_renderable
        return definitions if definition_children.nil? || definition_children.none?
        return definitions if definition_children.all?(String)

        definition_children
      end

      private

      def comparable_attributes
        super + %i[term terms definitions nested term_children definition_children attached_children]
      end
    end
  end
end
