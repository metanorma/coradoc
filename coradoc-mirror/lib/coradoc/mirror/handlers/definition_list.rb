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

          def definition_entry(item, context)
            term_node = build_term(item, context)
            desc_node = build_description(item, context)
            return nil unless term_node || desc_node

            [term_node, desc_node].compact
          end

          def build_term(item, context)
            term_text = item.term
            return nil unless term_text && !term_text.to_s.empty?

            term_children = item.term_children if item.is_a?(CoreModel::DefinitionItem)
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
            return nil if desc_nodes.empty?

            Node::DefinitionDescription.new(content: desc_nodes)
          end

          # Emit one text node per source — never both. Rich
          # definition_children (inline nodes) win over plain definitions
          # (strings) because they preserve formatting; falling back to
          # the plain string keeps this handler robust for DefinitionItem
          # instances populated by paths that don't build inline children.
          def description_nodes(item, context)
            unless item.is_a?(CoreModel::DefinitionItem)
              return Array(item.definitions).map { |defn| context.text_node(defn.to_s) }
            end

            children = item.definition_children
            return Array(item.definitions).map { |defn| context.text_node(defn.to_s) } if children.empty?

            children.flat_map { |child| Handlers::Inline.process_child(child, context) }
          end
        end
      end
    end
  end
end
