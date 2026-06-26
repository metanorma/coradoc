# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class DefinitionList < Base
        registers 'dl'

        def build(node)
          terms = []
          descriptions = []
          node.content&.each do |child|
            next unless child.is_a?(Node)

            case child.type
            when 'dt' then terms << build_node(child)
            when 'dd' then descriptions << build_node(child)
            end
          end

          items = terms.zip(descriptions).map do |term, desc|
            CoreModel::DefinitionItem.new(
              term: inline_content(term),
              definitions: [inline_content(desc)]
            )
          end

          CoreModel::DefinitionList.new(items: items)
        end
      end
    end
  end
end
