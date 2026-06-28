# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Abstract < Base
        def build(node)
          CoreModel::AbstractBlock.new(
            title: node.attrs&.title,
            id: node.attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
