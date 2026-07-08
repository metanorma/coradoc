# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module DefinitionList
        def self.call(element, context:)
          entries = Array(element.items).flat_map do |item|
            definition_entry(item, context)
          end
          return nil if entries.empty?

          Node::DefinitionList.new(
            attrs: Node::DefinitionList::Attrs.new(id: element.id),
            content: entries
          )
        end

        class << self
          private

          # One `<dt>` per term + one `<dd>` per item. Multi-term `<dt>`'s
          # (AsciiDoc `term1::\nterm2::\ndef`) emit two `<dt>` elements
          # sharing one `<dd>`. Single-term items — the common case —
          # emit one `<dt>` + one `<dd>`.
          def definition_entry(item, context)
            term_nodes = build_terms(item, context)
            desc_node = build_description(item, context)
            return nil if term_nodes.empty? && desc_node.nil?

            term_nodes + [desc_node].compact
          end

          # Emit one DefinitionTerm node per term in `item.terms`.
          # Falls back to `[term]` for items populated via paths that
          # only set the singular `term` accessor (backward compat).
          def build_terms(item, context)
            term_list = terms_for(item)
            return [] if term_list.empty?

            term_list.map { |term| build_term_node(term, item, context) }
          end

          # Source of truth for "the terms on this `<dt>`": the `terms`
          # collection when populated, else `[term]` for legacy callers.
          def terms_for(item)
            collection = item.terms if item.is_a?(CoreModel::DefinitionItem)
            return Array(collection) unless collection.nil? || collection.empty?

            primary = item.term
            primary.to_s.empty? ? [] : [primary.to_s]
          end

          # Build a single DefinitionTerm node for one term string,
          # carrying inline children when the source had them. Children
          # map 1:1 to the FIRST term only (multi-term `<dt>`'s with
          # inline markup on later terms is rare; the parser doesn't
          # capture per-term children today).
          def build_term_node(term_text, item, context)
            term_children = (item.term_children if (term_text == terms_for(item).first) && item.is_a?(CoreModel::DefinitionItem))
            if term_children && !term_children.empty?
              inline_nodes = term_children.flat_map do |child|
                Handlers::Inline.process_child(child, context)
              end
              return Node::DefinitionTerm.new(content: inline_nodes) unless inline_nodes.empty?
            end

            Node::DefinitionTerm.new(content: [context.text_node(term_text.to_s)])
          end

          def build_description(item, context)
            desc_nodes = description_nodes(item, context)
            attached_nodes = attached_block_nodes(item, context)
            nested_nodes = nested_dl_nodes(item, context)
            all_nodes = desc_nodes.concat(attached_nodes).concat(nested_nodes)
            return nil if all_nodes.empty?

            Node::DefinitionDescription.new(content: all_nodes)
          end

          # `+`-continuation blocks attached to this dd in AsciiDoc source
          # become children of the same DefinitionDescription node so they
          # render inside the same <dd> element. Dispatch each through
          # `context.transform_element` — same registry path as a top-level
          # walk, so every registered block handler (paragraph, admonition,
          # source, etc.) applies.
          def attached_block_nodes(item, context)
            return [] unless item.is_a?(CoreModel::DefinitionItem)
            return [] if item.attached_children.empty?

            item.attached_children.flat_map do |block|
              context.transform_element(block)
            end
          end

          # Multi-level dlist: AsciiDoc `::`/`:::`/`::::` delimiters
          # express nesting depth. The parser builds the tree
          # (CoreModel::DefinitionItem#nested); the mirror handler must
          # recurse so the nested <dl> renders INSIDE the parent <dd>.
          # Single source of truth: this method recurses through
          # `DefinitionList.call`, so nested items use the same dispatch
          # path as top-level items (DRY).
          def nested_dl_nodes(item, context)
            return [] unless item.is_a?(CoreModel::DefinitionItem)

            nested = item.nested
            return [] unless nested && nested.items.any?

            [DefinitionList.call(nested, context: context)].compact
          end

          # Emit one text node per source — never both. Rich
          # definition_children (inline nodes) win over plain definitions
          # (strings) because they preserve formatting; falling back to
          # the plain string keeps this handler robust for DefinitionItem
          # instances populated by paths that don't build inline children.
          def description_nodes(item, context)
            return Array(item.definitions).map { |defn| context.text_node(defn.to_s) } unless item.is_a?(CoreModel::DefinitionItem)

            children = item.definition_children
            return Array(item.definitions).map { |defn| context.text_node(defn.to_s) } if children.empty?

            children.flat_map { |child| Handlers::Inline.process_child(child, context) }
          end
        end
      end
    end
  end
end
