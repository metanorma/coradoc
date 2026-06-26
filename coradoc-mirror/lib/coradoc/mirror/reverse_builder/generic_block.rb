# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      # Catch-all for unrecognized block types emitted by the forward
      # direction (`Node::GenericBlock`). Preserves the semantic_type so
      # downstream consumers can dispatch on it.
      class GenericBlock < Base
        registers 'generic_block'

        def build(node)
          attrs = node.attrs
          CoreModel::Block.new(
            block_semantic_type: attrs&.semantic_type || 'generic',
            title: attrs&.title,
            id: attrs&.id,
            content: extract_text(node)
          )
        end
      end
    end
  end
end
