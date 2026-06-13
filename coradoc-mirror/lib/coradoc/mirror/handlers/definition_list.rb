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

          Node::DefinitionList.new(id: element.id, content: entries)
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
            definitions = item.definitions
            return nil unless definitions && !definitions.empty?

            desc_nodes = definitions.map do |defn|
              context.text_node(defn.to_s)
            end

            def_children = item.definition_children if item.is_a?(CoreModel::DefinitionItem)
            if def_children && !def_children.empty?
              def_children.each do |child|
                nodes = Handlers::Inline.process_child(child, context)
                desc_nodes.concat(Array(nodes)) if nodes && !nodes.empty?
              end
            end

            return nil if desc_nodes.empty?

            Node::DefinitionDescription.new(content: desc_nodes)
          end
        end
      end
    end
  end
end
