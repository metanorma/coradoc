# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Frontmatter < Base
        def build(node)
          attrs = node.attrs
          CoreModel::FrontmatterBlock.new(
            schema: attrs&.schema,
            entries: CoreModel::FrontmatterBlock::Codec.entries_from_hash(
              FrontmatterTreeToHash.to_hash(attrs&.entries || [])
            )
          )
        end
      end
    end
  end
end
